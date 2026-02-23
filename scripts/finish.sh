#!/bin/bash -eux

# Add a SSH key to the authorized keys for root account
[ -f /vagrant/scripts/ssh_keys ] && cat /vagrant/scripts/ssh_keys >> /root/.ssh/authorized_keys

# Uninstall Ansible and remove PPA.
apt -y remove --purge ansible

# Apt cleanup.
apt clean
apt autoremove -y

# cleanup different things
journalctl --vacuum-time=1s
rm -rf /tmp/*
rm -f /tmp/*
rm -rf /root/.cache/pip/*
rm -rf /var/lib/apt/lists/*
rm -f /var/lib/apt/lists/*
rm -f /var/log/*.gz

dpkg -l 'linux-image-*' | awk '/^ii/{ print $2}' | \
    grep -v "$(uname -r | cut -d- -f1,2)" | \
    xargs -r apt-get -y purge

# Delete unneeded files.
rm -f /home/vagrant/*.sh

# clear the Bash History
cat /dev/null > ~/.bash_history && history -c

# Zeroing the empty space
fallocate -l $(df --output=avail -k / | tail -1)K /EMPTY || true
rm -f /EMPTY
dd if=/dev/zero of=/EMPTY bs=1M || true
rm -f /EMPTY

# Add `sync` so Packer doesn't quit too early, before the large file is deleted.
sync

exit 0
