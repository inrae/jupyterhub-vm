#!/bin/bash

SOURCE=./ubuntu2204/
TARGET=../git/jupyterhub-vm/

(
   cd ../
   rsync -rav --exclude '*.vmdk' --exclude '*.log' $SOURCE $TARGET 
)
