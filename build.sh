#!/bin/bash
MYDIR=`dirname $0` && [ ! `echo "$0" | grep '^\/'` ] && MYDIR=`pwd`/$MYDIR

# VM parameters
VM_NAME="ubuntu1804"
VM_BOX=ubuntu-box.tar.gz
IP=192.168.99.1
DATA="/data"
#IP=dhcp
#DATA="none"

# Windows / Cygwin ?
RET=$(uname -a | grep -E "^CYGWIN" 1>/dev/null 2>/dev/null; echo $?)
if [ $RET -eq 0 ]; then
  USER=$(basename $USERPROFILE)
  MY_HOME=/cygdrive/c/Users/$USER
else
  MY_HOME=~
fi

PACKEREXE=$(which packer)
VAGRANTEXE=$(which vagrant)

LOG=$MYDIR/logs/vagrant.log
RESET=0
DESTROY=0
PACKER=0
UP=0
EXPORT=0

PWD=$(pwd)

# Get Cmd line arguments depending on options
while getopts cruped:i:l: opt
do
       case $opt in
       c) DESTROY=1
          ;;
       r) RESET=1
          ;;
       u) UP=1
          ;;
       p) PACKER=1
          ;;
       e) EXPORT=1
          ;;
       d) DATA=${OPTARG}
          ;;
       i) IP=${OPTARG}
          ;;
       l) LOG=${OPTARG}
          ;;
       esac
done
shift $((OPTIND-1))


# Delete local vagrant building environment
[ $RESET -eq 1 ] && rm -rf $MYDIR/.vagrant


#
# --- VAGRANT DESTROY ----
#
if [ $DESTROY -eq 1 ]; then
  # Destroy the default vagrant VM into VirtualBox
  $VAGRANTEXE halt -f default
  $VAGRANTEXE destroy -f default
  rm -rf $MY_HOME/VirtualBox\ VMs/$VM_NAME
fi


#
# --- PACKER ----
#
if [ $PACKER -eq 1 ]; then
  cd $MYDIR
  time $PACKEREXE build box-config.json | tee logs/packer.log
  rm -rf $MY_HOME/VirtualBox\ VMs/packer-ubuntu-18.04-amd64
  rm -rf $MYDIR/packer_cache
  cd $PWD
fi


#
# --- VAGRANT UP  ----
#
if [ $UP -eq 1 ]; then
  # Remove some ip from known_hosts
  KNOWN_HOSTS=~/.ssh/known_hosts
  
  remove_ip () {
     theIP=$1
     grep -v -E "($theIP |\[$theIP\])" $KNOWN_HOSTS > /tmp/known_hosts
     cat /tmp/known_hosts > $KNOWN_HOSTS
     rm -f /tmp/known_hosts
  }
  remove_ip $IP
  remove_ip 127.0.0.1

  # SSH-KEYS
  mkdir -p $MYDIR/files
  cp $MY_HOME/.vagrant.d/insecure_private_key $MYDIR/files/id_rsa
  chmod 700 $MYDIR/files/id_rsa
  ssh-keygen.exe -y -f $MYDIR/files/id_rsa > $MYDIR/files/id_rsa.pub
  ssh-add.exe $MYDIR/files/id_rsa

  # Remove previous local boxes
  [ -d $MY_HOME/.vagrant.d/boxes/file-* ] && rm -rf $MY_HOME/.vagrant.d/boxes/file-*

  # Log file
  [ -f $LOG ] && rm -f $LOG
  echo "" >> $LOG
  echo "#-------------------------------------------------------------------" >> $LOG
  echo "$> vagrant up" >> $LOG
  echo "" >> $LOG
  
  # Vagrantfile
  sed -e "s!<<VM_NAME>>!${VM_NAME}!g" \
      -e "s!<<MY_IP>>!${IP}!g" \
      -e "s!<<MY_DATA>>!${DATA}!g" \
      $MYDIR/Vagrantfile.tmpl > $MYDIR/Vagrantfile

  # Build & Launch the VM
  cd $MYDIR
  time $VAGRANTEXE up | tee -a $LOG
  rm -rf ./ansible/.cph_*
  rm -rf ./ansible/.empty
  cd $PWD
fi


#
# --- VAGRANT PACKAGE  ----
#
if [ $EXPORT -eq 1 ]; then
  [ ! -f $LOG ] && touch $LOG
  echo "" >> $LOG
  echo "#-------------------------------------------------------------------" >> $LOG
  echo "$> vagrant package --output $VM_BOX" >> $LOG
  echo "" >> $LOG

  time $VAGRANTEXE package --output $VM_BOX | tee -a $LOG

  # Remove previous local boxes
  [ -d $MY_HOME/.vagrant.d/boxes/file-* ] && rm -rf $MY_HOME/.vagrant.d/boxes/file-*

  $VAGRANTEXE destroy -f default | tee -a $LOG
  rm -rf $MY_HOME/VirtualBox\ VMs/$VM_NAME
  rm -rf $MYDIR/.vagrant
  rm -rf $MYDIR/files
  cd $MYDIR/builds/
  mkdir vm
  cd vm
  tar xvzf ../../$VM_BOX
  cd $PWD
  rm -f $MYDIR/$VM_BOX
fi


