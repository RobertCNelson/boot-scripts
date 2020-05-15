#!/bin/sh -e
#

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

if [ ! -d /boot/extlinux/ ] ; then
	mkdir /boot/extlinux/ || true
fi

uname_r=$(cat /boot/uEnv.txt  | grep -v "#" | grep uname_r)

#label Linux 4.14.108-ti-r131
#    kernel /boot/vmlinuz-4.14.108-ti-r131
#    append console=ttyO0,115200n8 root=/dev/mmcblk0p1 ro rootfstype=ext4 rootwait coherent_pool=1M net.ifnames=0 lpj=1990656 rng_core.default_quality=100
#    fdtdir /boot/dtbs/4.14.108-ti-r131/

echo "label Linux ${uname_r}"
echo "    kernel /boot/vmlinuz-${uname_r}"
echo "    append"
echo "    fdtdir /boot/dtbs/${uname_r}/"

