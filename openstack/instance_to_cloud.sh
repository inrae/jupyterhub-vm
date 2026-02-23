#!/bin/bash

MYDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

CLOUD=genostack
CLOUDFILE=~/.config/openstack/clouds.yaml
IMAGE_NAME=jupyterhub-img_2026
SERVER_NAME=jupystack_2026
KEYPAIR=genostack
FLAVOR_NAME=m1.xlarge

OS_SCRIPTS=`dirname $(which openstack)`
OS_USERNAME=djacob
OS_PASSWORD=
TEST=0

PWD=$(pwd)

usage() {
    echo "usage: sh $0 [-c <cloudname>] [-p <password>] [-i <VM IMAGE NAME>] [-s <instance name>] [-k <keypair>] [-f <flavor>] [-t]
     -c <cloudname>     : the entry in the clouds.yaml file (genostack by default)
     -p <password>      ! password to have access on the cloud
     -i <VM IMAGE NAME> : the image name of the VM once pushed on the cloud (jupyterhub-img_2026 by default)
     -s <instance name> : the instance name of the VM (jupystack_2026 by default)
     -k <keypair>       : genostack by default
     -f <flavor>        : m1.xlarge by default
     -t                 : flag indicating that it is just for testing cloud connection
"
    exit 1;
}

# Get Cmd line arguments depending on options
while getopts c:p:i:s:f:k:l:th opt
do
       case $opt in
       h) usage
          ;;
       c) CLOUD=${OPTARG}
          ;;
       p) OS_PASSWORD=${OPTARG}
          ;;
       f) FLAVOR_NAME=${OPTARG}
          ;;
       k) KEYPAIR=${OPTARG}
          ;;
       i) IMAGE_NAME=${OPTARG}
          ;;
       s) SERVER_NAME=${OPTARG}
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
  echo "Please enter your OpenStack Password: "
  read -sr OS_PASSWORD
fi

alias ostack="$OS_SCRIPTS/openstack --os-cloud=$CLOUD --os-password $OS_PASSWORD"

echo

# if test then list some features on the OpenStack server
if [ $TEST -eq 1 ]; then 
   echo "Server list:";   ostack server list
   echo
   echo "Flavor list:";   ostack flavor list
   echo
   echo "Kaypair list:";  ostack keypair list
   echo
   exit 0
fi


#---------------

# Create an instance to the OpenStack server from a snapshot/image

#ostack server delete jupystack

[ ! -f $CLOUDFILE ] && echo "ERROR: $CLOUDFILE not found" | tee -a $LOG && exit 1

grep_key() { grep -A7 "${CLOUD}:" $CLOUDFILE | grep " $1:" | sed -e "s/^ \+//" | cut -d' ' -f2; }
 
# Log file
echo "#"
echo "# CLOUD $CLOUD"
echo "#-------------------------------------------------------------------" | tee -a $LOG
echo "#"
echo "# IMAGE = $IMAGE_NAME"
echo "# SERVER_NAME = $SERVER_NAME"
echo "# FLAVOR = $FLAVOR_NAME"
echo "# KEYPAIR = $KEYPAIR"
echo "#"

IMAGEID=$(ostack image show $IMAGE_NAME | grep "| id " | cut -d'|' -f3 | sed -e "s/ //g")
FLAVORID=$(ostack flavor list | grep "$FLAVOR_NAME"  | cut -d'|' -f2 | sed -e "s/ //g")

(
  cd $MYDIR
  export OS_AUTH_URL=`grep_key auth_url`
  export OS_PROJECT_ID=`grep_key project_id`
  export OS_PROJECT_NAME=`grep_key project_name | sed -e "s/[\" ]\+//g"`
  export OS_USERNAME=`grep_key username | sed -e "s/[\" ]\+//g"`
  export OS_USER_DOMAIN_NAME=`grep_key user_domain_name | sed -e "s/[\" ]\+//g"`
  export OS_REGION_NAME=`grep_key region_name | sed -e "s/[\" ]\+//g"`
  export OS_INTERFACE=public
  export OS_IDENTITY_API_VERSION=3

  echo "# Create the instance $SERVER_NAME"
  ostack server create --flavor $FLAVORID --image $IMAGEID  \
           --user-data user-data-jupystack.txt \
           --key-name $KEYPAIR  $SERVER_NAME --config-drive true
  [ $? -ne 0 ] && echo "ERROR: The instance creation failed." && exit 1

  ostack server show $SERVER_NAME
)

