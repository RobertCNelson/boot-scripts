#!/bin/sh -e

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

cp -v /opt/scripts/device/bone/capes/ISM4334X/ISM4334X_NVRAM_C1.txt /lib/firmware/brcm/brcmfmac43341-sdio.txt
cp -v /opt/scripts/device/bone/capes/ISM4334X/ISM4334X_Wifi_FW_6.20.225.2_P.bin /lib/firmware/brcm/brcmfmac43341-sdio.bin

if [ ! -f /boot/initrd.img-$(uname -r) ] ; then
        update-initramfs -c -k $(uname -r)
else
        update-initramfs -u -k $(uname -r)
fi
