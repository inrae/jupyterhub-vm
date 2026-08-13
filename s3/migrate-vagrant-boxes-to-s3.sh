#!/usr/bin/env bash
#
# migrate-vagrant-boxes-to-s3.sh
#
# Exports locally installed Vagrant boxes, uploads them to S3,
# and generates the JSON metadata files needed for Vagrant to
# resolve them via `config.vm.box_url`.
#
# Prerequisites:
#   - vagrant (CLI) installed
#   - aws CLI installed and configured (aws configure / env vars)
#   - jq installed (JSON processing)
#   - An S3 bucket already created
#
# Usage:
#   ./migrate-vagrant-boxes-to-s3.sh -b my-bucket -p boxes/ [-n my-org] [--public]
#
#   IMPORTANT: this script must be run with bash, NOT with sh/dash:
#     bash ./migrate-vagrant-boxes-to-s3.sh ...
#     or: ./migrate-vagrant-boxes-to-s3.sh ...  (if chmod +x, thanks to the shebang)
#
#   -b, --bucket      S3 bucket name ONLY, no URL or host (required)
#                      e.g. bibs6   (NOT "https://my-host.fr:bibs6")
#   -p, --prefix      Prefix/folder within the bucket (default: "/")
#   -n, --namespace   Namespace to prepend to box names (e.g. "my-org")
#   -e, --endpoint    S3 endpoint URL if using a non-AWS S3-compatible store
#                      (e.g. https://s3-data.meso.umontpellier.fr)
#   --path-style      Force "path-style" URLs
#                      (https://endpoint/bucket/key) instead of
#                      "virtual-hosted-style" (https://bucket.endpoint/key).
#                      Recommended for most non-AWS S3-compatible storage
#                      (Ceph, MinIO, OpenStack Swift S3...).
#   --public          Make uploaded objects publicly readable (public-read ACL)
#   --box NAME        Migrate only a single box (by its Vagrant name, e.g. "ubuntu/jammy64")
#   --dry-run         Runs no upload, only shows what would be done
#   -h, --help        Show this help
#
if [ -z "${BASH_VERSION:-}" ]; then
  echo "[migrate][ERROR] This script requires bash. Run it with: bash $0 ..." >&2
  exit 1
fi

set -euo pipefail

# ---------------------------------------------------------------------------
# Default values
# ---------------------------------------------------------------------------

BUCKET=""
PREFIX=""
NAMESPACE=""
ENDPOINT=""
VERSION="1.0"
PATH_STYLE=true
PUBLIC_ACL=true
SINGLE_BOX=""
DRY_RUN=false
FULL_TREE=true
WORKDIR="$(mktemp -d ./vagrant-s3-migration.XXXXXX)"
REGION="us-east-1"

log()  { echo -e "[migrate] $*"; }
err()  { echo -e "[migrate][ERROR] $*" >&2; }

cleanup() {
  rm -rf $WORKDIR
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -b|--bucket) BUCKET="$2"; shift 2 ;;
    -p|--prefix) PREFIX="$2"; shift 2 ;;
    -n|--namespace) NAMESPACE="$2"; shift 2 ;;
    -e|--endpoint) ENDPOINT="$2"; shift 2 ;;
    -v|--version) VERSION="$2"; shift 2 ;;
    --path-style) PATH_STYLE=true; shift ;;
    --public) PUBLIC_ACL=true; shift ;;
    --box) SINGLE_BOX="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) grep '^#' "$0" | sed 's/^#//'; exit 0 ;;
    *) err "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$BUCKET" ]]; then
  err "The S3 bucket is required (-b / --bucket)."
  exit 1
fi

if [[ "$BUCKET" == *"://"* || "$BUCKET" == *":"* ]]; then
  err "The -b/--bucket parameter must contain ONLY the bucket name, no URL."
  err "Received: '$BUCKET'"
  err "If you're using non-AWS S3 storage, pass the host URL via -e/--endpoint,"
  err "and give just the bucket name to -b. Example:"
  err "  -e https://s3-data.meso.umontpellier.fr -b bibs6"
  exit 1
fi

# The prefix must end with a /
if [[ "$PREFIX" != */ ]]; then
  PREFIX="${PREFIX}/"
fi

# Strip any trailing / from the endpoint
if [[ -n "$ENDPOINT" ]]; then
  ENDPOINT="${ENDPOINT%/}"
fi

# Build the --endpoint-url arguments for the aws cli, if applicable
AWS_ENDPOINT_ARGS=()
if [[ -n "$ENDPOINT" ]]; then
  AWS_ENDPOINT_ARGS=(--endpoint-url "$ENDPOINT")
fi

for cmd in vagrant aws jq sha256sum; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    err "'$cmd' is required but was not found in PATH."
    exit 1
  fi
done

log "Temporary working directory: $WORKDIR"
log "Target bucket: s3://${BUCKET}/${PREFIX}"
if [[ -n "$ENDPOINT" ]]; then
  log "Custom S3 endpoint: $ENDPOINT (style: $([[ "$PATH_STYLE" == true ]] && echo path-style || echo virtual-hosted))"
fi

# ---------------------------------------------------------------------------
# 1. List locally installed boxes (name, provider, version)
#    Format of `vagrant box list --machine-readable`:
#    timestamp,target,type,data
#    IMPORTANT: for `box list`, the "target" field is ALWAYS EMPTY.
#    The actual box name is found in the "data" field (4th column):
#      1614556800,,box-name,ubuntu/jammy64
#      1614556800,,box-provider,virtualbox
#      1614556800,,box-version,20210301.0.0
# ---------------------------------------------------------------------------
log "Reading the list of local boxes (vagrant box list)..."

declare -A BOX_PROVIDER
declare -A BOX_VERSION
ORDER=()

current_target=""
while IFS=',' read -r _ts _target type data; do
  case "$type" in
    box-name)
      current_target=$(echo "$data" | sed -e "s/\r//")
      ;;
    box-provider)
      if [[ -n "$current_target" ]]; then
        BOX_PROVIDER["$current_target"]=$(echo "$data" | sed -e "s/\r//")
        ORDER+=("$current_target")
      fi
      ;;
    box-version)
      if [[ -n "$current_target" ]]; then
        BOX_VERSION["$current_target"]=$(echo "$data" | sed -e "s/\r//")
      fi
      ;;
  esac
done < <(vagrant box list --machine-readable)

# ---------------------------------------------------------------------------
# 2. Main loop: for each box -> repackage, checksum, upload
# ---------------------------------------------------------------------------

# Maps each box_name to the list of its already-processed (version:provider)
# entries, in order to rebuild a cumulative metadata.json per box.
declare -A METADATA_ENTRIES  # key: box_name -> value: accumulated JSON array (string)

process_box() {
  local box_name="$1"
  local provider="${BOX_PROVIDER[$box_name]}"
  local version="${BOX_VERSION[$box_name]}"

  local final_name="$box_name"
  if [[ -n "$NAMESPACE" ]]; then
    final_name="${NAMESPACE}/$(basename "$box_name")"
  fi

  log "----------------------------------------------------------------"
  log "Box: $box_name  |  provider: $provider  |  version: $version"
  log "Final name on S3/registry: $final_name"

  local safe_name
  safe_name="$(echo "$final_name" | tr '/' '-')"
  local box_filename="${safe_name}-${version}-${provider}.box"
  local local_box_path="${WORKDIR}/${box_filename}"

  # 2a. Repackage the box from the local Vagrant cache (~/.vagrant.d/boxes)
  #     WARNING: `vagrant box repackage NAME PROVIDER VERSION` does NOT
  #     accept an --output option. It always generates a "package.box"
  #     file in the current directory; we rename it ourselves afterwards.
  log "Exporting (repackage) the box to $local_box_path ..."
  if [[ "$DRY_RUN" == false ]]; then
    (
      cd "$WORKDIR"
      rm -f package.box
      vagrant box repackage "$box_name" "$provider" "$version"
      mv package.box "$box_filename"
    )
  else
    log "[dry-run] (cd \"$WORKDIR\" && vagrant box repackage \"$box_name\" \"$provider\" \"$version\" && mv package.box \"$box_filename\")"
    touch "$local_box_path"  # placeholder for the rest of the dry-run
  fi

  # 2b. Compute the SHA256 checksum
  local checksum=""
  if [[ "$DRY_RUN" == false ]]; then
    checksum="$(sha256sum "$local_box_path" | awk '{print $1}')"
  else
    checksum="dryrun0000000000000000000000000000000000000000000000000000000"
  fi
  log "SHA256: $checksum"

  # 2c. Upload to S3
  local s3_key
  if [[ $version -eq 0 && ! -s $VERSION ]]; then
    version=$VERSION
  fi
  if [[ "$FULL_TREE" == true ]]; then
    s3_key="${PREFIX}${final_name}/${version}/${provider}.box"
  else
    s3_key="${PREFIX}${safe_name}/${version}/${provider}/${box_filename}"
  fi
  local s3_uri="s3://${BUCKET}/${s3_key}"

  local acl_args=()
  if [[ "$PUBLIC_ACL" == true ]]; then
    acl_args=(--acl public-read)
  fi

  log "Uploading to $s3_uri ..."
  if [[ "$DRY_RUN" == false ]]; then
    aws s3 cp "$local_box_path" "$s3_uri" "${AWS_ENDPOINT_ARGS[@]}" "${acl_args[@]}"
  else
    log "[dry-run] aws s3 cp \"$local_box_path\" \"$s3_uri\" ${AWS_ENDPOINT_ARGS[*]:-} ${acl_args[*]:-}"
  fi

  # 2d. Build the public URL
  #     - Standard AWS: virtual-hosted-style (bucket.s3.region.amazonaws.com)
  #     - Custom endpoint: path-style by default (endpoint/bucket/key),
  #       or virtual-hosted-style if explicitly requested (--path-style not passed)
  local public_url
  if [[ -n "$ENDPOINT" ]]; then
    if [[ "$PATH_STYLE" == true ]]; then
      public_url="${ENDPOINT}/${BUCKET}/${s3_key}"
    else
      # Rebuilds host.tld by inserting the bucket as a prefix (virtual-hosted)
      local scheme host
      scheme="${ENDPOINT%%://*}"
      host="${ENDPOINT#*://}"
      public_url="${scheme}://${BUCKET}.${host}/${s3_key}"
    fi
  elif [[ -n "$REGION" && "$REGION" != "us-east-1" ]]; then
    public_url="https://${BUCKET}.s3.${REGION}.amazonaws.com/${s3_key}"
  else
    public_url="https://${BUCKET}.s3.amazonaws.com/${s3_key}"
  fi

  # 2e. Add the entry to the in-memory metadata array
  local entry
  entry=$(jq -n \
    --arg version "$version" \
    --arg provider "$provider" \
    --arg url "$public_url" \
    --arg checksum "$checksum" \
    '{version: $version, provider: $provider, url: $url, checksum_type: "sha256", checksum: $checksum}')

  local key="$final_name"
  if [[ -z "${METADATA_ENTRIES[$key]:-}" ]]; then
    METADATA_ENTRIES["$key"]="[$entry]"
  else
    # Merges into the existing array
    METADATA_ENTRIES["$key"]="$(jq -c ". + [$entry]" <<< "${METADATA_ENTRIES[$key]}")"
  fi

  # Clean up the local .box file so as not to fill up the disk
  if [[ "$DRY_RUN" == false ]]; then
    rm -f "$local_box_path"
  fi
}

for box_name in "${ORDER[@]}"; do
  if [[ -n "$SINGLE_BOX" && "$box_name" != "$SINGLE_BOX" ]]; then
    continue
  fi
  process_box "$box_name"
done

if [[ ${#METADATA_ENTRIES[@]} -eq 0 ]]; then
  err "No box processed (check --box if used)."
  exit 1
fi

# ---------------------------------------------------------------------------
# 3. Generate + upload the metadata.json files (one per box_name),
#    grouping together all known versions/providers.
# ---------------------------------------------------------------------------
log "================================================================"
log "Generating metadata files..."

for final_name in "${!METADATA_ENTRIES[@]}"; do
  safe_name="$(echo "$final_name" | tr '/' '-')"
  entries="${METADATA_ENTRIES[$final_name]}"

  # Groups entries by version -> providers[]
  metadata_json=$(jq -n \
    --arg name "$final_name" \
    --argjson entries "$entries" \
    '{
      name: $name,
      versions: (
        $entries
        | group_by(.version)
        | map({
            version: .[0].version,
            providers: map({
              name: .provider,
              url: .url,
              checksum_type: .checksum_type,
              checksum: .checksum
            })
          })
      )
    }')

  local_meta_path="${WORKDIR}/${safe_name}-metadata.json"
  echo "$metadata_json" | jq '.' > "$local_meta_path"

  if [[ "$FULL_TREE" == true ]]; then
    meta_s3_key="${PREFIX}${final_name}/metadata.json"
  else
    meta_s3_key="${PREFIX}${safe_name}/metadata.json"
  fi
  meta_s3_uri="s3://${BUCKET}/${meta_s3_key}"

  acl_args=()
  if [[ "$PUBLIC_ACL" == true ]]; then
    acl_args=(--acl public-read)
  fi

  log "Metadata for '$final_name' -> $meta_s3_uri"
  if [[ "$DRY_RUN" == false ]]; then
    aws s3 cp "$local_meta_path" "$meta_s3_uri" \
      --content-type "application/json" "${AWS_ENDPOINT_ARGS[@]}" "${acl_args[@]}"
  else
    log "[dry-run] aws s3 cp \"$local_meta_path\" \"$meta_s3_uri\" --content-type application/json ${AWS_ENDPOINT_ARGS[*]:-} ${acl_args[*]:-}"
  fi
done

log "================================================================"
log "Migration to S3 complete."