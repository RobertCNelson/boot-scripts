#!/bin/sh -e

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

cp -v /opt/scripts/device/bone/capes/ISM4343W/4343w_bcmdhd.txt /lib/firmware/brcm/brcmfmac4343-sdio.txt
cp -v /opt/scripts/device/bone/capes/ISM4343W/4343w_fw_bcmdhd.bin /lib/firmware/brcm/brcmfmac4343-sdio.bin

if [ ! -f /boot/initrd.img-$(uname -r) ] ; then
	update-initramfs -c -k $(uname -r)
else
	update-initramfs -u -k $(uname -r)
fi
