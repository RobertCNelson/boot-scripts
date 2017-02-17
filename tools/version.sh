#!/bin/sh -e
#

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

if [ -f /etc/dogtag ] ; then
	cat /etc/dogtag
fi

if [ -b /dev/mmcblk0 ] ; then
	#U-Boot
	dd if=/dev/mmcblk0 count=6  skip=393248 bs=1 2>/dev/null
	#U-Boot 2017.03-rc1-00003-gad8008
	dd if=/dev/mmcblk0 count=32 skip=393248 bs=8 2>/dev/null
fi

if [ -b /dev/mmcblk1 ] ; then
        #U-Boot
        dd if=/dev/mmcblk0 count=6  skip=393248 bs=1 2>/dev/null
        #U-Boot 2017.03-rc1-00003-gad8008
        dd if=/dev/mmcblk1 count=32 skip=393248 bs=8 2>/dev/null
fi

uname -r

