# Migrating Vagrant boxes to S3

This folder contains a script to migrate your Vagrant boxes hosted locally
to an S3 bucket.

## Prerequisites

- `vagrant` (CLI) installed, with the boxes already present locally
  (`vagrant box list` must list them — otherwise run
  `vagrant box add <name>` first to fetch them before the service shuts down).
- `aws` CLI installed and configured (`aws configure`, or the
  `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_DEFAULT_REGION`
  environment variables).
- `jq` installed.
- An S3 bucket already created, with write permissions for your
  IAM user/role.

## Usage

> ⚠️ **The script must be run with `bash`, not `sh`** (it uses bash
> associative arrays). The script detects this and refuses to continue
> if you run it with `sh`, but it's worth knowing upfront:
> ```bash
> bash ./migrate-vagrant-boxes-to-s3.sh ...
> # or, once chmod +x has been done:
> ./migrate-vagrant-boxes-to-s3.sh ...
> ```

```bash
# Make the script executable (one-time)
chmod +x migrate-vagrant-boxes-to-s3.sh

# Dry run (no real upload, simulation only)
./migrate-vagrant-boxes-to-s3.sh -b my-bucket -n my-org --dry-run

# Real migration of all local boxes (standard AWS S3)
./migrate-vagrant-boxes-to-s3.sh -b my-bucket -n my-org

# Migrate a single box
./migrate-vagrant-boxes-to-s3.sh -b my-bucket -n my-org --box ubuntu/jammy64

# If the bucket must be publicly accessible over HTTP (no AWS credentials)
./migrate-vagrant-boxes-to-s3.sh -b my-bucket -n my-org --public
```

### Non-AWS S3-compatible storage (Ceph, MinIO, OpenStack Swift S3, etc.)

Many institutions (regional computing centers, universities, private
clouds) expose S3-compatible storage but with their own hostname rather
than `amazonaws.com`. In that case, use `-e/--endpoint` for the host URL,
and `-b/--bucket` **only** for the bucket name (never the full URL):

```bash
# Example: S3-compatible storage at the Montpellier regional computing center
./migrate-vagrant-boxes-to-s3.sh \
  -e https://s3-data.meso.umontpellier.fr \
  -b bibs6 \
  -p djacob/boxes \
  -n djacob \
  --path-style
```

The `--path-style` option (URLs as `https://endpoint/bucket/key` rather
than `https://bucket.endpoint/key`) is recommended for most non-AWS
S3-compatible storage; `virtual-hosted-style` (the default, without this
option) only works if the provider's DNS correctly routes
`<bucket>.<endpoint>` subdomains, which is rare outside of AWS.

Also make sure your credentials are properly configured for this
endpoint, via `aws configure` or the `AWS_ACCESS_KEY_ID` /
`AWS_SECRET_ACCESS_KEY` variables provided by your host (often different
from your regular AWS credentials).

### Options

| Option              | Description                                                        |
|---------------------|----------------------------------------------------------------------|
| `-b, --bucket`      | S3 bucket name only, no URL or host (required)                       |
| `-p, --prefix`      | Folder/prefix within the bucket (default: `boxes/`)                  |
| `-n, --namespace`   | Namespace applied to boxes (e.g. `my-org/ubuntu-jammy64`)            |
| `-e, --endpoint`    | S3 endpoint URL for non-AWS storage (e.g. `https://s3-data.meso.umontpellier.fr`) |
| `--path-style`      | Force `endpoint/bucket/key`-style URLs (recommended outside AWS)     |
| `--public`          | Upload with `public-read` ACL                                        |
| `--box NAME`        | Migrate only a specific box (Vagrant name as listed)                 |
| `--dry-run`         | Runs no `vagrant box repackage` or `aws s3 cp` commands               |

## What the script does

1. Reads `vagrant box list --machine-readable` to find out about the
   boxes, their providers (virtualbox, libvirt, etc.), and their
   versions.
2. For each box: `vagrant box repackage` regenerates a `.box` file
   from the local cache (`~/.vagrant.d/boxes`), without needing to
   re-download from Vagrant Cloud.
3. Computes the SHA256 checksum of the `.box` file.
4. Uploads the `.box` to S3 under the following structure:
   ```
   s3://<bucket>/<prefix>/<safe-name>/<version>/<provider>/<safe-name>-<version>-<provider>.box
   ```
5. Generates (and uploads) a `metadata.json` file per box, grouping
   together all known versions and providers — this is the file
   Vagrant consumes to resolve `vagrant box update` and handle
   multiple providers/architectures.
6. Produces a summary with the ready-to-copy-paste Vagrantfile snippet
   for each migrated box (saved to
   `/mnt/user-data/outputs/vagrantfile-snippets.txt`).

## Private bucket vs. public bucket

- **`--public`**: objects are accessible via anonymous HTTP. Simple,
  but be careful if your boxes contain sensitive material (keys,
  internal configuration, etc.).
- **Private bucket (default)**: Vagrant does not natively know how to
  authenticate to S3 with AWS credentials during a `vagrant up`. Two
  options:
  - Generate **presigned URLs** (limited validity, to be regenerated
    and updated periodically in the `Vagrantfile` / `metadata.json`);
  - Put **CloudFront** (or an internal reverse proxy) in front of the
    bucket with authentication suited to your organization (VPN, IP
    allowlist, CloudFront signed cookies, etc.), and point
    `config.vm.box_url` at CloudFront rather than directly at S3.

## Updating the Vagrantfile

Once the migration is done, each project must replace:

```ruby
config.vm.box = "my-org/ubuntu-jammy64"
```

with (example generated by the script):

```ruby
Vagrant.configure("2") do |config|
  config.vm.box     = "my-org/ubuntu-jammy64"
  config.vm.box_url = "https://my-bucket.s3.amazonaws.com/boxes/my-org-ubuntu-jammy64/metadata.json"
end
```

Vagrant will use this `metadata.json` file to automatically find the
right version and provider, exactly as it did via Vagrant Cloud —
`vagrant box update` will therefore keep working.

## Known limitations

- `vagrant box repackage` regenerates the `.box` from the local cache —
  the box must therefore have already been downloaded at least once on
  the machine running the script. This subcommand has no `--output`
  option: it always generates a `package.box` file in the current
  directory, which the script then renames itself.
- The script does not handle rotation/deletion of old versions on S3;
  add an S3 lifecycle rule if needed.
- The checksum is computed on the locally repackaged file: if you have
  several build environments, make sure to always use the same
  machine/tooling version to guarantee the reproducibility of the
  `.box`.