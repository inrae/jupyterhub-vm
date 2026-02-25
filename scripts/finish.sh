#!/bin/bash -eux

# Add a SSH key to the authorized keys for root account
[ -f /vagrant/scripts/ssh_keys ] && cat /vagrant/scripts/ssh_keys >> /root/.ssh/authorized_keys

# Uninstall Ansible
apt -y remove --purge ansible

# Cleaning apt cache
apt-get clean
apt-get autoremove -y

# Cleaning logs
rm -f /var/log/*.gz
find /var/log -type f -exec truncate -s 0 {} \;

# Removing shell history
rm -f /root/.bash_history
rm -f /home/*/.bash_history || true

# Cleaning /tmp
rm -rf /tmp/*
rm -rf /var/tmp/*

# Cleaning journalctl
journalctl --vacuum-time=1s

# Cleaning pip cache
rm -rf /root/.cache/pip/*

dpkg -l 'linux-image-*' | awk '/^ii/{ print $2}' | \
    grep -v "$(uname -r | cut -d- -f1,2)" | \
    xargs -r apt-get -y purge

# Delete unneeded files.
rm -f /home/vagrant/*.sh

# Zeroing the empty space
fallocate -l $(df --output=avail -k / | tail -1)K /EMPTY || true
rm -f /EMPTY
dd if=/dev/zero of=/EMPTY bs=1M || true
rm -f /EMPTY

# Add `sync` so Packer doesn't quit too early, before the large file is deleted.
sync

exit 0
