#!/bin/bash -eux

# Add a SSH key to the authorized keys for root account
[ -f /vagrant/scripts/ssh_keys ] && cat /vagrant/scripts/ssh_keys >> /root/.ssh/authorized_keys

# Uninstall Ansible
apt -y remove --purge ansible

# Cleaning apt cache
apt-get clean
apt-get autoremove -y
rm -rf /var/lib/apt/lists/*

# Cleaning logs
find /var/log -type f -exec truncate -s 0 {} \;

# Cleaning cloud-init state
cloud-init clean --logs
rm -rf /var/lib/cloud/*
#echo 'datasource_list: [ OpenStack, ConfigDrive, NoCloud ]' > /etc/cloud/cloud.cfg.d/90_dpkg.cfg
echo 'datasource_list: [ OpenStack, openstack ]' > /etc/cloud/cloud.cfg.d/90_dpkg.cfg

# Resetting machine-id
truncate -s 0 /etc/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id
rm -f /var/lib/dbus/machine-id

# Removing shell history
rm -f /root/.bash_history
rm -f /home/*/.bash_history || true

# Removing SSH host keys
rm -f /etc/ssh/ssh_host_*

# Cleaning /tmp
rm -rf /tmp/*
rm -rf /var/tmp/*


# Cleaning journalctl
journalctl --vacuum-time=1s

# Cleaning some other thins ...
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
dd if=/dev/zero of=/EMPTY bs=1M || true
rm -f /EMPTY

# Add `sync` so Packer doesn't quit too early, before the large file is deleted.
sync

exit 0
