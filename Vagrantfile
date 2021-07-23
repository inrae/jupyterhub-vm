# -*- mode: ruby -*-
# -*- encoding: utf-8 -*-
# vi: set ft=ruby :

## Variables

#BOX_NAME = "file://builds/virtualbox-ubuntu1804.box"

BOX_NAME = "djacob65/small-ubuntu1804"
BOX_VERSION = "1.0.1"

APP_NAME="ubuntu"
VM_NAME="ubuntu1804"
MY_IP="dhcp"
MY_DATA="none"

## Vagrant version
Vagrant.require_version ">= 2.0.0"

## Plugins
unless Vagrant.has_plugin?("virtualbox")
  raise 'Missing virtualbox plugin! Make sure to install it by `vagrant plugin install virtualbox`.'
end

Vagrant.configure("2") do |config|

  config.vm.box = BOX_NAME
  config.vm.box_version = BOX_VERSION
  config.vm.hostname = APP_NAME

  if MY_IP.eql?("dhcp")
    config.vm.network "private_network", type: "dhcp"
  else
    config.vm.network "private_network", ip: MY_IP
  end

  config.vm.provider "virtualbox"  do |vb|
    vb.name = VM_NAME
    vb.memory = 2048
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--cpuexecutioncap", "100"]
  end

  config.ssh.insert_key = false

  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
  if MY_DATA != "none"
    config.vm.synced_folder MY_DATA, "/media/sf_DATA", type: "virtualbox"
  end

  config.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "ansible/playbook.yml"
      ansible.install = true
      ansible.limit = 'all'
  end

  config.vm.provision "shell", path: "scripts/cleanup.sh"

end
