#!/bin/bash -e

sudo dd if=/dev/zero of=/dev/mmcblk1 bs=1M count=16
sudo touch /boot/uboot/flash-eMMC.txt
