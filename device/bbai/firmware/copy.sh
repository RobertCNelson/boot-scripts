#!/bin/bash

sudo cp -v ./*.bin /lib/firmware/brcm/ ;\
sudo cp -v ./*.txt /lib/firmware/brcm/ ;\
sudo cp -v ./*.clm_blob /lib/firmware/brcm/ ;\
sudo update-initramfs -uk `uname -r`
