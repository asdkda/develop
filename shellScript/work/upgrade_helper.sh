#!/bin/bash

IMG_NAME=${1:0:${#1}-4}
img_update.sh  tftp://10.2.10.142/$1
config_boot $IMG_NAME
reboot

