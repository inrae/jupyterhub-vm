---
title: Openstack Cloud
summary: 
authors:
    - Daniel Jacob
date: 2021-07-01
some_url:
---

# Openstack Cloud

<style>.md-typeset h1 {display: none;} .md-nav__item {font-size: medium}</style>


[GenOuest][1]{:target="_blank"} is a national bioinformatics platform federated by the [French Institute of Bioinformatics][2]{:target="_blank"} (IFB). This platform offers cloud services for the French public research community. Any researcher from this community can make a request to Genouest or any other IFB platform to have access to the proposed services.

GenOuest offers on its datacenter infrastructure a service of providing computing resources in the form of virtual machines. The infrastructure is managed using [Openstack][3]{:target="_blank"}, which is a set of open source software that allows the deployment of cloud computing infrastructures (Infrastructure as a Service, IaS). It is therefore necessary to have a valid account on this infrastructure (see the [online help][4]{:target="_blank"}).

It is then assumed that you have installed Python (≥2.7) as well as the [package python-openstackclient][5]{:target="_blank"} . 

<br>

#### Retrieving its connection settings from GenOuest Openstack

To set the required environment variables for openstack command line clients, you must download the environment file called openrc.sh from the [GenOuest openStack dashboard][6]{:target="_blank"} as a user. This project-specific environment file contains the credentials that all openstack services use.

<br>
<center>
<a href="../images/image3.png" data-lightbox="image3"><img src="../images/image3.png" width="600px"></a>
</center><br><br>

**Note**: All the scripts and other configuration files mentioned in this description can be found in free access under the [GiHub INRAE repository][8]{:target="_blank"}.

<br>

You need to get the *openrc.sh* script as well as the *cloud.yml* configuration file. The latter is to be put in the *<home directory\>/.config/openstack* directory.

Then run the *openrc.sh* script in the current shell (i.e invoking using a dot); you will be asked for your password.

```shell
$> . ./openrc.sh
Please enter your OpenStack Password for project <Project> as user <Users>:
```

* *<Project\>* and *<User\>* corresponding to your configuration.

This script will define the following variables: OS_AUTH_URL, OS_PROJECT_DOMAIN_ID, OS_REGION_NAME, OS_PROJECT_NAME, OS_USER_DOMAIN_NAME, OS_IDENTITY_API_VERSION, OS_INTERFACE, OS_USERNAME, OS_PROJECT_ID, OS_PASSWORD


In addition, in order to simplify the written of commands, we will define some aliases.

```shell
OS_SCRIPTS=<path of the python-openstackclient scripts>

alias ostack="$OS_SCRIPTS/openstack --os-cloud=openstack --os-password $OS_PASSWORD"
alias onova="$OS_SCRIPTS/nova --os-password $OS_PASSWORD"
```

<br>

If everything is configured correctly, the following command should provide you with a list of available flavors. Flavours define the hardware configuration available for a server. It defines the size of a virtual server that can be started.

```shell
$> ostack flavor list
```
```
+------------+-------+------+-------+-----------+
 | Name       |   RAM | Disk | VCPUs | Is Public |
 +------------+-------+------+-------+-----------+
 | m2.xlarge  | 16384 |   20 |     4 | True      |
 | m1.small   |  2048 |   20 |     1 | True      |
 | m2.large   |  8192 |   20 |     2 | True      |
 | m1.medium  |  4096 |   20 |     2 | True      |
 | m2.4xlarge | 65536 |   20 |     8 | True      |
 | m2.medium  |  4096 |   20 |     1 | True      |
 | m1.2xlarge | 32768 |   20 |     8 | True      |
 | m1.large   |  8192 |   20 |     4 | True      |
 | m1.xlarge  | 16384 |   20 |     8 | True      |
 | m2.2xlarge | 32768 |   20 |     4 | True      |
 +------------+-------+------+-------+-----------+
```

<br>


We will then proceed in two steps:

1. create a VM image within the library
2. create an instance of this image

<br>
<center>
<a href="../images/image4.png" data-lightbox="image4"><img src="../images/image4.png" width="600px"></a>
</center><br><br>

#### Creating the image on the openstack infrastructure

It is first necessary to extract the VM file in VMDK format from the archive generated in the previous step.

```shell
$> tar xvzf <path of the archive file>/ubuntu-box.tar.gz box-disk001.vmdk
```
This is the file that will be used to create the image. You must also specify a name for the image. 

Then the command below will create the image from the VM file. This command can take several minutes to be achieved.

```shell
IMAGE_NAME=jupyterhub-image

ostack image create --disk-format vmdk --file box-disk001.vmdk $IMAGE_NAME

ostack image set --property description='JupyterHub with R and Python' $IMAGE_NAME

ostack image show $IMAGE_NAME
```

As a result you should obtained something like below:
```
+------------------+----------------------------------------------------------+
| Field            | Value                                                    |
+------------------+----------------------------------------------------------+
| checksum         | 2a8e9789322009839401be1c25b3d977                         |
| container_format | bare                                                     |
| created_at       | 2021-09-09T06:49:14Z                                     |
| disk_format      | vmdk                                                     |
| file             | /v2/images/d88e2d16-9c67-4f07-a5dd-20d68f80ba0f/file     |
| id               | d88e2d16-9c67-4f07-a5dd-20d68f80ba0f                     |
| min_disk         | 0                                                        |
| min_ram          | 0                                                        |
| name             | jupyterhub-img                                           |
| owner            | xxxxxxxxxxxxxxxxxxxxxxxxxx                               |
| properties       | description='JupyterHub with R and Python'               |
| protected        | False                                                    |
| schema           | /v2/schemas/image                                        |
| size             | 3666548736                                               |
| status           | active                                                   |
| tags             |                                                          |
| updated_at       | 2021-09-09T07:02:16Z                                     |
| visibility       | shared                                                   |
+------------------+----------------------------------------------------------+
```


<br>

#### Creating an instance from the created image

From the created image, it is now possible to create an instance. You have to specify the name of the instance, its flavor (see above) and the SSH key associated to this VM. The SSH key (keypair) must first have been created from the openstack dashboard.

* You can list the SSH keys with the command:
```shell
ostack keypair list
```

* An SSH key has been created with the name *genostack* in the openstack dashboard. This [SSH key][7]{:target="_blank"} must be a valid key on your (linux) openstack.genouest.org account(file *~/.ssh/authorized_keys*).

* For flavor we choose in our example the one corresponding to 8 CPUs, 16GB of RAM and 20GB of disk.

* You can also specify the file containing the commands to be executed after the first boot. Here this file is necessary (*[user-data-jupystack.txt][20]{:target="_blank"}*) because we must overwrite the file */usr/local/bin/get-hostname* giving the complete name of the instance on openstack in order to build the root URL of the jupyterhub application (cf *[jupyterhub.pre][21]{:target="_blank"}* and *[jupyterhub.service][22]{:target="_blank"}*).

<br>

Now, we are ready to launch the command to create the VM isntance.

```shell
IMAGE_NAME=jupyterhub-image
SERVER_NAME=jupystack
KEYPAIR=genostack
FLAVOR_NAME=m1.xlarge

IMAGEID=$(ostack image show $IMAGE_NAME | \
           grep "| id " | cut -d'|' -f3 | \ 
           sed -e "s/ //g")
FLAVORID=$(ostack flavor list | \
           grep "$FLAVOR_NAME"  | cut -d'|' -f2 | \
           sed -e "s/ //g")

onova boot --flavor $FLAVORID --image $IMAGEID --security-groups default \
           --user-data ./user-data-jupystack.txt \
           --key-name $KEYPAIR  $SERVER_NAME
```

Once launched, the construction of the VM instance is underway, and its status is "building". So you have to wait until the VM status is "Running" (~ one minute or more).

To see the status, launch the command below :

```shell
ostack server show $SERVER_NAME
```

You should probably rereun this last command

Finally you should obtained something like below:

```
+-----------------------------+---------------------------------------------------------+
| Field                       | Value                                                   |
+-----------------------------+---------------------------------------------------------+
| OS-DCF:diskConfig           | MANUAL                                                  |
| OS-EXT-AZ:availability_zone | nova                                                    |
| OS-EXT-STS:power_state      | Running                                                 |
| OS-EXT-STS:task_state       | None                                                    |
| OS-EXT-STS:vm_state         | active                                                  |
| OS-SRV-USG:launched_at      | 2021-09-09T07:09:49.000000                              |
| OS-SRV-USG:terminated_at    | None                                                    |
| accessIPv4                  |                                                         |
| accessIPv6                  |                                                         |
| addresses                   | genouest-ext=192.168.101.79                             |
| config_drive                | True                                                    |
| created                     | 2021-09-09T07:08:05Z                                    |
| flavor                      | m1.xlarge (c781b97e-f891-4ddf-9a6b-0e5ae4ef3eb1)        |
| hostId                      | 126a5d6324eb3765547b4d2e3c5743509afde064a7d90ff1db2fb58a|
| id                          | 0146be96-0c4f-413b-b3a5-bde37cdabb26                    |
| image                       | jupyterhub-image (d88e2d16-9c67-4f07-a5dd-20d68f80ba0f) |
| key_name                    | genostack                                               |
| name                        | jupystack                                               |
| progress                    | 0                                                       |
| project_id                  | xxxxxxxxxxxxxxxxxxxxxxxxx                               |
| properties                  |                                                         |
| security_groups             | name='default'                                          |
| status                      | ACTIVE                                                  |
| updated                     | 2021-09-09T07:09:49Z                                    |
| user_id                     | xxxxxxxxxxxxxxxxxxxxxxxxx                               |
| volumes_attached            |                                                         |
+-----------------------------+---------------------------------------------------------+
```

<br>

The last command is also used to obtain the IP number of the VM thus created. The IP addresse is given by the field 'addresses'. Let's suppose that this IP number is *192.168.101.79*.  You can then access the application from your web browser at the URL: *https://app-192-168-101-79.vm.openstack.genouest.org/hub/login*

<br>
<center>
<a href="../images/image5.png" data-lightbox="image5"><img src="../images/image5.png" width="600px"></a>
</center><br><br>

### Acknowledgements

We would like to thank the [IFB GenOuest bioinformatics][9]{:target="_blank"} for providing storage and computing resources on its national life science Cloud.


---

* [Additional document](../gcpimg/PuTTY_WinSCP.pdf){:target="_blank"}: Slides that show, step by step, how to copy data, scripts and notebooks to the shared folder of the Jupyterhub server, in a secure way (SCP) using PuTTY and WinSCP.

---

<br><br><br>

[1]: https://www.genouest.org/
[2]: https://www.france-bioinformatique.fr/
[3]: https://www.openstack.org/
[4]: https://help.genouest.org/
[5]: https://docs.openstack.org/newton/user-guide/common/cli-install-openstack-command-line-clients.html
[6]: https://www.youtube.com/embed/XcQYz--CNiM?ab_channel=UKCloudLtd
[7]: http://www.genouest.org/outils/genostack/ssh-config.html
[8]: https://github.com/inrae/jupyterhub-vm/tree/master/openstack
[9]: https://www.genouest.org/2017/03/02/cluster/

[20]: https://github.com/inrae/jupyterhub-vm/blob/master/openstack/user-data-jupystack.txt
[21]: https://github.com/inrae/jupyterhub-vm/blob/master/ansible/roles/jupyterhub/files/bin/jupyterhub.pre
[22]: https://github.com/inrae/jupyterhub-vm/blob/master/ansible/roles/jupyterhub/files/systemd/jupyterhub.service
