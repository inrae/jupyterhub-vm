## Littlest JupyterHub

[JupyterHub](https://jupyter.org/hub) runs in the cloud or on your own hardware, and makes it possible to serve a pre-configured data science environment to any user in the world. It is customizable and scalable, and is suitable for small and large teams, academic courses, and large-scale infrastructure.

The [Littlest JupyterHub](https://tljh.jupyter.org/), a recent and evolving distribution designed for smaller deployments, is a lightweight method to install JupyterHub on a single virtual machine. The Littlest JupyterHub (also known as TLJH), provides a guide with information on creating a VM on several cloud providers, as well as installing and customizing JupyterHub so that users may access it at a public URL.

### Creation and configuration of a virtual machine

Requires [VirtualBox](https://www.virtualbox.org/), [Packer](https://www.packer.io/), [Vagrant](https://www.vagrantup.com/) to be installed beforehand.

* **VirtualBox**: this is what we call the "supplier". If the objective is to use the VM on his desktop computer, then the VM will have to run in VirtualBox. If the objective is to use the VM in the cloud (OpenStack for example), then VirtualBox is only used here as an intermediary to build the VM.

* **Packer** : allows the creation of a virtual machine from an ISO, having a very precise control over its characteristics. Here it will allow us to build a VM compatible with the Vagrant tool.

* **Vagrant** : will allow us to provision our VM with [Ansible](https://www.ansible.com/).

* **Ansible** which is a powerfull tool allowing to describe tasks using a langage, then turn tough tasks into repeatable playbooks. It is **not necessary to install Ansible** beforehand. It will be installed temporarily on the virtual machine to proceed the provisionning. It will be removed at the end.

![Overview](https://raw.githubusercontent.com/djacob65/jupyterhub-vm/master/images/overview.png)





