#!/bin/bash -eux

# Install VBoxGuestAdditions
mkdir -p /media/cdrom
mount -t iso9660 -o loop /home/vagrant/VBoxGuestAdditions.iso /media/cdrom
sh /media/cdrom/VBoxLinuxAdditions.run
umount /media/cdrom
rm -f /home/vagrant/VBoxGuestAdditions.iso

# Install some packages
apt-get update && apt-get install -y \
   whois curl rsync cloud-init apt net-tools


# ssh key
mkdir /home/vagrant/.ssh
chmod 0700 /home/vagrant/.ssh
wget -O/home/vagrant/.ssh/authorized_keys https://github.com/mitchellh/vagrant/raw/master/keys/vagrant.pub
chown -R vagrant:vagrant /home/vagrant/.ssh
chmod 0600 /home/vagrant/.ssh/authorized_keys

mkdir /root/.ssh
chmod 0700 /root/.ssh
cp /home/vagrant/.ssh/authorized_keys /root/.ssh/
chmod 0600 /root/.ssh/authorized_keys


SSHD_CONFIG=sshd_config

# Accelerate SSH connections
sed -i "s/^.*UseDNS.*$/UseDNS no/" /etc/ssh/${SSHD_CONFIG}
sed -i "s/^.*GSSAPIAuthentication.*$/GSSAPIAuthentication no/" /etc/ssh/${SSHD_CONFIG}

# Enable root to login
sed -i "s/^.*PermitRootLogin.*$/PermitRootLogin yes/" /etc/ssh/${SSHD_CONFIG}
perl -i -pe 's/disable_root: true/disable_root: false/' /etc/cloud/cloud.cfg

chown root:root /etc/ssh/${SSHD_CONFIG}
chmod 0600 /etc/ssh/${SSHD_CONFIG}

# Add vagrant user to sudoers.
echo "vagrant        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

# Disable daily apt unattended updates.
echo 'APT::Periodic::Enable "0";' >> /etc/apt/apt.conf.d/10periodic

