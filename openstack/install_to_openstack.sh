#!/usr/bin/env bash
MYDIR=`dirname $0` && [ ! `echo "$0" | grep '^\/'` ] && MYDIR=`pwd`/$MYDIR

# Run the OpenStack RC File (Identity API v3.0) - See README.md
. ./openrc_v3.sh

alias ostack="$(which openstack) --os-cloud=openstack --os-password $OS_PASSWORD"
alias onova="$(which nova) --os-password $OS_PASSWORD"

unset OS_PASSWORD
 
# List your instances on the OpenStack server
ostack server list

#---------------

# List flavors on the OpenStack server
ostack flavor list

# Genostack flavors (January, 2021) - https://genostack.genouest.org/dashboard/
# +------------+-------+------+-------+-----------+
# | Name       |   RAM | Disk | VCPUs | Is Public |
# +------------+-------+------+-------+-----------+
# | m2.xlarge  | 16384 |   20 |     4 | True      |
# | m1.small   |  2048 |   20 |     1 | True      |
# | m2.large   |  8192 |   20 |     2 | True      |
# | m1.medium  |  4096 |   20 |     2 | True      |
# | m2.4xlarge | 65536 |   20 |     8 | True      |
# | m2.medium  |  4096 |   20 |     1 | True      |
# | m1.2xlarge | 32768 |   20 |     8 | True      |
# | m1.large   |  8192 |   20 |     4 | True      |
# | m1.xlarge  | 16384 |   20 |     8 | True      |
# | m2.2xlarge | 32768 |   20 |     4 | True      |
# +------------+-------+------+-------+-----------+

ostack security group list
# Genostack security groups (January, 2021) - https://genostack.genouest.org/dashboard/
# +--------------------------------------+---------+------------------------+
# | ID                                   | Name    | Description            |
# +--------------------------------------+---------+------------------------+
# | 1fc2329c-c191-45fc-8e60-eb32fb9d1b9a | default | Default security group |
# +--------------------------------------+---------+------------------------+

ostack keypair list

# Genostack key pairs (January, 2021) - https://genostack.genouest.org/dashboard/
# +-----------+
# | Name      |
# +-----------+
# | default   |
# | genostack |
# | vagrant   |
# +-----------+

#---------------

# Create an image to the OpenStack server from a local VM file (format VDI, VMDK, QCOW2, OVA, ... )

IMAGE_NAME=jupyterhub-image
FORMAT=vmdk

ostack image create --disk-format $FORMAT --file $MYDIR/../builds/vm/box-disk001.$FORMAT $IMAGE_NAME

ostack image set --property description='JupyterHub with R and Python' $IMAGE_NAME

ostack image show $IMAGE_NAME

#ostack image delete $IMAGE_NAME

#---------------

# Create an instance to the OpenStack server from a snapshot/image

#ostack server delete jupystack

IMAGE_NAME=jupyterhub-image
FORMAT=vmdk

SERVER_NAME=jupystack
KEYPAIR=genostack
FLAVOR_NAME=m1.xlarge

IMAGEID=$(ostack image show $IMAGE_NAME | grep "| id " | cut -d'|' -f3 | sed -e "s/ //g")
FLAVORID=$(ostack flavor list | grep "$FLAVOR_NAME"  | cut -d'|' -f2 | sed -e "s/ //g")


onova boot --flavor $FLAVORID --image $IMAGEID --security-groups default \
           --user-data $MYDIR/user-data-jupystack.txt \
           --key-name $KEYPAIR  $SERVER_NAME

ostack server show $SERVER_NAME

