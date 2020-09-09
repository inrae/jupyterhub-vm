#!/bin/bash -eux

function finish {
  [ -f /tmp/EMPTY ] && rm -f /tmp/EMPTY
}
trap finish ERR

# Uninstall Ansible and remove PPA.
apt -y remove --purge ansible
apt-add-repository --remove ppa:ansible/ansible

# Apt cleanup.
apt autoremove
apt update

# Delete unneeded files.
rm -f /home/vagrant/*.sh

# Zero out the rest of the free space using dd, then delete the written file.
dd if=/dev/zero of=/tmp/EMPTY bs=1M
[ -f /tmp/EMPTY ] && rm -f /tmp/EMPTY

# Add `sync` so Packer doesn't quit too early, before the large file is deleted.
sync

exit 0
