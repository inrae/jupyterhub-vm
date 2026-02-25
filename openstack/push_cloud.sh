#!/bin/bash

MYDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Default parameters
CLOUD=genostack
IMAGE_NAME=jupyterhub-img_2026
VMFILE=./builds/ubuntu2204-disk001.vmdk
OS_SCRIPTS=`dirname $(which openstack)`
OS_PASSWORD=
TEST=0

PWD=$(pwd)

usage() {
    echo "usage: sh $0 [-c <cloudname>] [-p <password>] [-d <vmdk file>] [-i <image name>] [-t]
     -c <cloudname>     : the entry in the clouds.yaml file (genostack by default)
     -p <password>      : password to have access on the cloud
     -d <vmdk file>     : the full path of the VM disk (./builds/ubuntu2204-disk001.vmdk by default)
     -i <image name>    : the image name of the VM once pushed on the cloud (jupyterhub-img_2026 by default)
     -t                 : flag indicating that it is just for testing cloud connection
"
    exit 1;
}

# Get Cmd line arguments depending on options
while getopts c:p:i:l:th opt
do
       case $opt in
       h) usage
          ;;
       c) CLOUD=${OPTARG}
          ;;
       p) OS_PASSWORD=${OPTARG}
          ;;
       d) VMFILE=${OPTARG}
          ;;
       i) IMAGE_NAME=${OPTARG}
          ;;
       l) LOG=${OPTARG}
          ;;
       t) TEST=1
          ;;
       *) usage
       esac
done
shift $((OPTIND-1))

err_report() {
    echo "Error:  the openstack command on cloud $CLOUD failed"
    exit 1
}
trap 'err_report' ERR

if [ -z $OS_PASSWORD ]; then
  echo "Please enter your OpenStack password, then [shift][Enter] :"
  read -sr OS_PASSWORD
fi

alias ostack="$OS_SCRIPTS/openstack --os-cloud=$CLOUD --os-password $OS_PASSWORD"

echo
echo "Wait ..."

[ $TEST -eq 1 ] && ostack server list && exit 0
 
# Log file
echo "#"
echo "# CLOUD $CLOUD"
echo "#-------------------------------------------------------------------"
echo "#"

[ ! -f $VMFILE ] && echo "ERROR: $VMFILE not found" && exit 1
FORMAT=$(echo $VMFILE | sed -e "s/^.*\.\([a-z0-9]\+\)$/\1/")
 
echo "# VMFILE = $VMFILE"
echo "# FORMAT = $FORMAT"
echo "#"
echo "# Create the image $IMAGE_NAME"
echo "#"

time ostack image create --disk-format $FORMAT --file $VMFILE $IMAGE_NAME
[ $? -ne 0 ] && echo "ERROR: The virtual machine deployment failed."&& exit 1

ostack image set --property description='JupyterHub for R Applications' $IMAGE_NAME
[ $? -ne 0 ] && echo "ERROR: The description failed." && exit 1

ostack image show $IMAGE_NAME | tee -a $LOG
[ $? -ne 0 ] && echo "ERROR: The image display failed." && exit 1

echo OK

#ostack image delete $IMAGE_NAME
