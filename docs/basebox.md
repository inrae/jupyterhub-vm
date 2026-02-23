---
title: Base Box
summary: 
authors:
    - Daniel Jacob
date: 2021-07-01
some_url:
---

# Base Box

<style>.md-typeset h1 {display: none;} .md-nav__item {font-size: medium}</style>


#### Building the base VM (Base box) for Vagrant

It is assumed that you have installed the [Packer][1]{:target="_blank"} and [Vagrant tools][2]{:target="_blank"}, as well as the [Oracle VirtualBox][3]{:target="_blank"} virtualisation software.

The operations for creating a base box are documented online; you have to follow the [basic guide][4]{:target="_blank"} and apply the provider-specific rules, namely for [VirtualBox][5]{:target="_blank"} . The procedure is somewhat tedious and, above all, an error can happen quickly. This is why we will use the Packer tool, which allows to fully automate the creation of a Vagrant base box by following the process illustrated by the figure below:

<br>
<center>
<a href="../images/image1.png" data-lightbox="image1"><img src="../images/image1.png" width="600px"></a>
</center><br><br>

**Note**: All the scripts and other configuration files mentioned in this description can be found in free access under the [GiHub INRAE repository][10]{:target="_blank"}.

We are using [Ubuntu version 20.04][6]{:target="_blank"} as a basis.

A Packer configuration is defined with a JSON file (box-config.json) with several sections: 

* [builders][20]{:target="_blank"}: is used to define the elements for creating the virtual machine from an ISO image.
* [provisioners][21]{:target="_blank"}: is used to define the software configuration from Shell scripts to provision the virtual machine.
* [post-processors][22]{:target="_blank"}: runs once the virtual machine is created and provisioned. This allows among other things to define the output format of the VM.

**"builders" section**

* To build this section, it is often simpler to start from already functional examples and to modify the few elements specific to its configuration. A query in a search engine (e.g. Google) with the keywords "github packer ubuntu 20.04 virtualbox" will give you enough examples. So we started with [an example appropriate to our needs][7]{:target="_blank"}, which we then adapted.
* The VirtualBox box is made from an Ubuntu ISO specified by its URL (iso_urls) in order to create the VM in VirtualBox ("type": "virtualbox-iso") .
* A "preseed" file (http/preseed.cfg) allows to configure the installation (see more info on [preseeding][8]{:target="_blank"} ). We have adapted the example by adding instructions concerning the root account and the network configuration.
* We limited the maximum disk size to 18GB ("disk_size": 18432) so that the final VM can be accepted by the [Genouest cloud][11]{:target="_blank"}.

**"provisioners" section**

This section allows to run Shell scripts after the virtual machine has booted properly and then its operating system installed. So it is in this step that we can configure the VM to be compatible with Vagrant and VirtualBox. A Shell script (scripts/setup.sh) is then executed in order to:

* install the drivers for VirtualBox
* configure SSH accesses in compliance with Vagrant boxes. 

**"post-processors" section**

* Once the base virtual machine is fully installed and configured, it is simply exported to Vagrant format. 


#### Creating the base VM

Before building, you must install these external plugins to ensure builds keep working 

```
$> packer plugins install github.com/hashicorp/virtualbox
$> packer plugins install github.com/hashicorp/vagrant
```

Once the configuration has been established, simply run Packer as follows:

```
$> packer build box-config.json
```

All the messages produced can be consulted on the [github repository][9]{:target="_blank"}. The base VM after execution can be found under the builds directory.

<br><br>

#### Registering a box on Vagrant Cloud

Vagrant Cloud provides an API that allows users to register their virtual machines (boxes) with Vagrant Cloud so that they can be reused by themselves or by other users.  The use of the [API is described online][12]{:target="_blank"}. 

The registration of a virtual machine can only be done with the Vagrant format, i.e. a "box". A "box" is in fact a zipped archive file (TAR + GZIP) with the extension '.box'.
Registering a "box" consists of 5 steps:

1. Creating an entry for the "box": at least the name of the box (boxname) must be specified. Its description is optional.
2. Creating a version: there may be several versions of the same entry; the version must be specified.
3. Creation of a provider: similarly, for an entry (boxname) and a version, there may be several associated providers; the provider must be specified.
4. Upload the box file.
5. Validate the box. (entry + version + provider)

All of these steps can be done either via the Vagrant Cloud web interface, or through multiple API calls. In order to facilitate the automation of registrations, the Vagrant tool provides a 'cloud' functionality that allows you to register your box on Vagrant Cloud. This requires an account (called an 'organisation') to be created on Vagrant Cloud. 

Example of invocation : 

```
$> vagrant cloud auth login
```
```
 ...
Vagrant Cloud username: GAEV
Vagrant Cloud password: XXXXXXX
```

```
$> vagrant cloud publish GAEV/centos7-dd8Gb 1.0.0 virtualbox virtualbox-centos7_8Gb.box 
```
```
You are about to create a box on Vagrant Cloud with the following options:
GAEV/centos7-dd8Gb (1.0.0) for virtualbox
Automatic Release:     true
Do you wish to continue? [y/N] y
Creating a box entry...
Creating a version entry...
Creating a provider entry...
Uploading provider with file /Vagrant/boxes/virtualbox-centos7_8Gb.box
Releasing box...
Complete!
tag:                  GAEV/centos7-dd8Gb
username:             GAEV
name:                 centos7-dd8Gb
private:              false
downloads:            0
created_at:           2020-07-25T17:53:04.340Z
updated_at:           2020-07-25T18:01:10.665Z
current_version:      1.0.0
providers:            virtualbox
```

The registered box can be viewed on [Vagrant Cloud][13]{:target="_blank"}.

<br><br><br>

[1]: https://www.packer.io/downloads
[2]: https://www.vagrantup.com/downloads
[3]: https://www.virtualbox.org/wiki/Downloads
[4]: https://developer.hashicorp.com/vagrant/docs/boxes/base
[5]: https://developer.hashicorp.com/vagrant/docs/providers/virtualbox/boxes
[6]: http://cdimage.ubuntu.com/ubuntu/releases/20.04/release/
[7]: https://github.com/geerlingguy/packer-boxes/tree/master/ubuntu2004
[8]: https://wiki.debian.org/DebianInstaller/Preseed

[9]: https://github.com/inrae/jupyterhub-vm/blob/master/logs/packer.log
[10]: https://github.com/inrae/jupyterhub-vm
[11]: https://www.genouest.org/tag/cloud/
[12]: https://www.vagrantup.com/docs/cli/cloud
[13]: https://portal.cloud.hashicorp.com/vagrant/discover/GAEV/ubuntu1804-dd18Gb

[20]: https://developer.hashicorp.com/packer/docs/builders
[21]: https://developer.hashicorp.com/packer/docs/provisioners
[22]: https://developer.hashicorp.com/packer/docs/post-processors
