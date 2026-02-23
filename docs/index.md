---
title: Home
summary: 
authors:
    - Daniel Jacob
date: 2021-07-01
some_url:
---

# Home

<style>.md-typeset h1 {display: none;} .md-nav__item {font-size: medium}</style>

## Generation of a virtual machine (VM) from an ubuntu server installation image (ISO file)

* containing [The Littlest JupyerHub][2]{:target="_blank"} (TLJH)
* with the help of [Packer][5]{:target="_blank"}, [Vagrant][6]{:target="_blank"} and [Ansible][7]{:target="_blank"} tools
* for using with [VirtualBox][8]{:target="_blank"} or [OpenStack][9]{:target="_blank"}.

All the tools used are exclusively free and open-source.

The [Littlest JupyterHub][2]{:target="_blank"}, a recent and evolving distribution designed for smaller deployments, is a lightweight method to install JupyterHub on a single virtual machine. The Littlest JupyterHub (also known as TLJH), provides a guide with information on creating a VM on several cloud providers, as well as installing and customizing JupyterHub so that users may access it at a public URL.

### Overview

This work was carried on a desktop computer running Windows10 / Cygwin. But any machine (laptop, desktop, server, ...) under MacOS or UNIX-like can be perfectly suitable. Please note that this requires technical skills in installing applications and assumes that you are comfortable editing configuration files. 

**Note**: All the scripts and other configuration files mentioned in this description can be found in free access under the [GiHub INRAE repository][3]{:target="_blank"}.

To build our final VM, i.e. the VM that will be instantiated for use locally ([type 2 virtualization][4]{:target="_blank"}) or on a remote server (Datacenter or Cloud), we will proceed in two main steps for the creation. The first step will consist in the building of a base VM (Base box). The second step will consist, from the base VM, in installing and configuring all the system and application tools (packages) necessary to make JupyterHub work correctly from a web browser. A third step will describe how to instantiate the final VM on the Genouest cloud. The figure below gives an overview: 

<br>
<center>
<a href="images/overview.png" data-lightbox="overview"><img src="images/overview.png" width="600px"></a>
</center><br><br>

**The three main stages**

1. [Building the base VM (Base box) for Vagrant](basebox)
2. [Building the final VM](finalvm)
3. [Using the final VM on an Openstack cloud](os-cloud)

**Pipeline**

* In green, the pipeline path for the creation, storage and instantiation of the virtual machine.
* As input to the pipeline, an ISO file corresponding to the chosen operating system and downloaded from the Internet. 
* At the output, an instance of the virtual machine operational on Genouest's Openstack cloud.

**The different layers**

* The *configuration* layer corresponds to all the files and scripts deposited in the github.
* The *creation* layer corresponds to all the tools installed and used on the user's local machine (except for Ansible which is installed on the virtual machine but which could very well be installed on the local machine).
* The *storage* layer corresponds to the storage sites of the VMs (base and final).
* The *instantiation* layer corresponds to the instantiated virtual machine.

<br><br><br>

[1]: https://jupyter.org/hub
[2]: https://tljh.jupyter.org/
[3]: https://github.com/inrae/jupyterhub-vm
[4]: https://medium.com/teamresellerclub/type-1-and-type-2-hypervisors-what-makes-them-different-6a1755d6ae2c
[5]: https://www.packer.io
[6]: https://www.vagrantup.com
[7]: https://docs.ansible.com/
[8]: https://www.virtualbox.org
[9]: https://www.openstack.org/
