## Littlest JupyterHub

[JupyterHub](https://jupyter.org/hub) runs in the cloud or on your own hardware, and makes it possible to serve a pre-configured data science environment to any user in the world. It is customizable and scalable, and is suitable for small and large teams, academic courses, and large-scale infrastructure.

The [Littlest JupyterHub](https://tljh.jupyter.org/), a recent and evolving distribution designed for smaller deployments, is a lightweight method to install JupyterHub on a single virtual machine. The Littlest JupyterHub (also known as TLJH), provides a guide with information on creating a VM on several cloud providers, as well as installing and customizing JupyterHub so that users may access it at a public URL.

### Creation and configuration of a virtual machine

Requires [VirtualBox](https://www.virtualbox.org/), [Packer](https://www.packer.io/), [Vagrant](https://www.vagrantup.com/) to be installed beforehand.

* **VirtualBox**: this is what we call the "provider". If the objective is to use the VM on his desktop computer, then the VM will have to run in VirtualBox. If the objective is to use the VM in the cloud (OpenStack for example), then VirtualBox is only used here as an intermediary to build the VM.

* **Packer** : allows the creation of a virtual machine from an ISO, having a very precise control over its characteristics. Here it will allow us to build a VM compatible with the Vagrant tool.

* **Vagrant** : will allow us to provision our VM with [Ansible](https://docs.ansible.com/ansible/latest/index.html).

* **Ansible** which is a powerfull tool allowing to describe tasks using a langage, then turn tough tasks into repeatable playbooks. It is **not necessary to install Ansible** beforehand. It will be installed temporarily on the virtual machine to proceed the provisionning. It will be removed at the end of the VM creation.

![Overview](https://raw.githubusercontent.com/djacob65/jupyterhub-vm/master/images/overview.png)


#### Configuration files

* **http/preseed.cfg** : Debian-based VM [preconfiguration file](https://wiki.debian.org/DebianInstaller/Preseed) (ubuntu). 
* **box-config.json** : configuration file used by Packer to define what image we want built. In particular, you can adjust the disk size (18 Go).
* **Vagranfile.tmpl** : template for the configuration file used by Vagrant to describe the type of the machine and how to configure and provision it. This template file is used by the build.sh script to generate the real Vagrant file used by Vagrant.
* **ansible/vars/all.yml** : Variable definition file used by ansible to configure the installation of the VM and the packages, modules, etc. In particular, you can put here all R packages and Python modules to be installed and available in Jupyter notebooks.


#### Steps to follow

The shell script **build.sh** can run each step separately or all at the same time. 

**Note**: You must edit this file before launching to ensure that the paths to the packer and vagrant binary programs match your configuration. In the case of an installation under Windows 10 / Cygwin 64 bits for example, it would be a good idea to specify the correct paths directly in the script. You can change the default IP and the default data path (shared data).

1. Generate the vagrant box based on Packer.
```
   $> sh ./build.sh -p
```
   The script launches the command _packer build box-config.json_.
   As results, a vagrant box will be generate under the builds folder.

2. Generate the VM into VirtualBox
```
   $> sh ./build.sh -u
```
   The script launches the command _vagrant up_.
   As results, a VM will created into VirtualBox. You can test it. You can also made a SSH connection in 2 ways :
        * First,  ssh -p2222 vagrant@127.0.0.1
        * Second  ssh vagrant@<IP of your VM>
   In both cases, no passord will bas asked if ssh-agent running. Otherwise, enter _vagrant_ as passord.
   
   The default IP and the default data path (shared data) are those defined in the build.sh script.
   * To specify another IP, use the _-i_ option. VirtualBox will create the corresponding Ethernet adapters. You need to specify _-i dhcp_ if the VM is to be run on the cloud.
   * To specify another data folder, use the _-d_ option. You need to specify _-d none_ if the VM is to be run on the cloud.

3. Export the VM 
```
   $> sh ./build.sh -e
```
   The script launches the command _vagrant package_.
   As results, a VM file will created under the builds/vm folder. You can use it as a virtual appliance into VirtualBox or in an OpenStack cloud.

All steps can be run at the same time:
```
   $> sh ./build.sh -pue -i <IP> -d <shared data folder>
```






