#!/bin/sh -e

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

cp -v /opt/scripts/device/bone/capes/ISM43362/ISM43362_NVRAM_C1.txt /lib/firmware/brcm/brcmfmac43362-sdio.txt
cp -v /opt/scripts/device/bone/capes/ISM43362/ISM43362_WiFi_FW_5.90.225.0_P.bin /lib/firmware/brcm/brcmfmac43362-sdio.bin

if [ ! -f /boot/initrd.img-$(uname -r) ] ; then
        update-initramfs -c -k $(uname -r)
else
        update-initramfs -u -k $(uname -r)
fi
