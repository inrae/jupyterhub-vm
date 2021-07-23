## Purpose

Building automation of a virtual machine (VM) from a [server install image of ubuntu](http://cdimage.ubuntu.com/ubuntu/releases/bionic/release/) (ISO file)

* containing _The Littlest JupyerHub_ (TLJH)
* with the help of _Packer_, _Vagrant_ and _Ansible_ tools 
* for using with _VirtualBox_ or _OpenStack_.


For more details on the whole process, see https://inrae.github.io/jupyterhub-vm/

### Creation and configuration of a virtual machine

Requires [VirtualBox](https://www.virtualbox.org/), [Packer](https://www.packer.io/), [Vagrant](https://www.vagrantup.com/) to be installed beforehand.

* **VirtualBox**: this is what we call the [provider](https://www.vagrantup.com/docs/providers). If the objective is to use the VM on his desktop computer, then the VM will have to run in _VirtualBox_. If the objective is to use the VM in the cloud (_OpenStack_ for example), then _VirtualBox_ is only used here as an intermediary to build the VM.

* **Packer** : allows the creation of a virtual machine from an ISO, having a very precise control over its characteristics. Here it will allow us to build a VM compatible with the Vagrant tool, called a box.

* **Vagrant** : allows building virtual machines from basic building blocks called [boxes](https://app.vagrantup.com/boxes/search) for [Providers](https://www.vagrantup.com/docs/providers) by [provisioning](https://www.vagrantup.com/docs/provisioning) them by _Provisioners_ such as [Ansible](https://docs.ansible.com/ansible/latest/index.html).

* **Ansible** which is a powerfull tool allowing to describe tasks using [Playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks.html), then turn tough tasks into repeatable playbooks. It is **not necessary to install Ansible** beforehand. It will be installed temporarily on the virtual machine to proceed the [provisionning](https://www.vagrantup.com/docs/provisioning). It will be removed at the end of the VM creation.

![Overview](https://raw.githubusercontent.com/inrae/jupyterhub-vm/master/images/overview.png)


#### Configuration files

* **http/preseed.cfg** : Debian-based VM [preconfiguration file](https://wiki.debian.org/DebianInstaller/Preseed) (ubuntu). 
* **box-config.json** : configuration file used by Packer to define what image we want built. In particular, you can adjust the disk size (18 Gb).
* **Vagrantfile.tmpl** : template for the configuration file used by _Vagrant_ to describe the type of the machine and how to configure and provision it. This template file is used by the _build.sh_ script (see below) to generate the real _Vagrantfile_ used by Vagrant.
* **ansible/vars/all.yml** : Variable definition file used by ansible to configure the installation of the VM and the packages, modules, etc. In particular, you can put here all R packages and Python modules to be installed and available in Jupyter notebooks.


#### Steps to follow

The shell script **build.sh** can run each step separately or all at the same time. 

**Note**: You must edit this file before launching to ensure that the paths to the packer and vagrant binary programs match your configuration. In the case of an installation under _Windows 10 / Cygwin 64 bits_ for example, it would be a good idea to specify the correct paths directly in the script. You can change the default IP and the default data path (shared data).

1. Generate the vagrant box based on Packer.
```
   $> sh ./build.sh -p
```
   The script launches the command _packer build box-config.json_.
   As results, a vagrant box will be generated under the _builds_ folder.

2. Generate the VM into _VirtualBox_
```
   $> sh ./build.sh -u
```
   The script launches the command _vagrant up_.
   As results, a VM will create into _VirtualBox_. You can test it. You can also made a SSH connection in 2 ways :

        * First,  ssh -p2222 vagrant@127.0.0.1
        * Second  ssh vagrant@<IP of your VM>
   In both cases, no password will be asked if ssh-agent running. Otherwise, enter _vagrant_ as password.

   The default IP and the default data path (shared data) are those defined in the _build.sh_ script.
   * To specify another IP, use the _-i_ option. _VirtualBox_ will create the corresponding Ethernet adapters. You need to specify _-i dhcp_ if the VM is to be run on the cloud.
   * To specify another data folder, use the _-d_ option. You need to specify _-d none_ if the VM is to be run on the cloud. In the latter case,  you can put files (data, scripts) under the _ansible/roles/jupyterhub/files/share_ folder so that they are included in the shared folder within the VM and accessible in the 'shared_data' folder in jupyter notebooks.  This folder can also be replaced by a symbolic link pointing to another folder containing the data and/or scripts to be shared.

3. Export the VM 
```
   $> sh ./build.sh -e
```
   The script launches the command _vagrant package_.
   As results, a VM file will create under the _builds/vm_ folder. You can use it as a virtual appliance into _VirtualBox_ or in an OpenStack cloud.

All steps can be run at the same time:
```
   $> sh ./build.sh -pue -i <IP> -d <shared data folder>
```


#### Using JupyterHub

The first time you log in to JupyterHub via the web interface, you must enter the administrator's login and password. The administrator's login is _admin_ (configured in the file _ansible/roles/jupyterhub/tasks/install.yml_).

![Login](https://raw.githubusercontent.com/inrae/jupyterhub-vm/master/images/jupyterhub_login.png)

The password is to be set by entering it when logging in for the first time. Then, it is registered as a user account of the machine (Linux account). Thus, you will have to enter the same password for subsequent logins. To change it, you will have to connect to the VM via a console and change it with the command _passwd_.







