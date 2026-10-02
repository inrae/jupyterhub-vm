# -*- mode: ruby -*-
# -*- encoding: utf-8 -*-
# vi: set ft=ruby :


## You must get the small-ubuntu2204.box before

# 1- Using the S3 storage
#ENV['AWS_PROFILE']='default'
#ENV['AWS_ENDPOINT_URL']='https://s3-data.meso.umontpellier.fr'
#BOX_PATH = "bibs6/djacob/boxes"
#BOX_NAME = "djreg/small-ubuntu2204"
#BOX_URL = "#{ENV['AWS_ENDPOINT_URL']}/#{BOX_PATH}/#{BOX_NAME}/metadata.json"

# 2- Using the Google Drive
BOX_NAME = "small-ubuntu2204"
BOX_URL = "file://#{File.expand_path("builds/#{BOX_NAME}.box", __dir__)}"
GOOGLEID = "1QM-BXuCwH_YFc20jgtNXMYVH4hsqs1DE"
system("gdown -O ./builds/#{BOX_NAME}.box #{GOOGLEID}") unless File.exist?("./builds/#{BOX_NAME}.box")

## Others Variables
APP_NAME="ubuntu"
VM_NAME="ubuntu2204"
MY_IP="192.168.99.1"
MY_DATA="none"

## Vagrant version
Vagrant.require_version ">= 2.0.0"

## Plugins
unless Vagrant.has_plugin?("virtualbox")
  raise 'Missing virtualbox plugin! Make sure to install it by `vagrant plugin install virtualbox`.'
end

Vagrant.configure("2") do |config|

  config.vm.box = BOX_NAME
  config.vm.box_url = BOX_URL
  config.vm.hostname = APP_NAME

  config.vm.network "private_network", ip: MY_IP

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

  config.vm.provision "shell", path: "scripts/finish.sh"

end
