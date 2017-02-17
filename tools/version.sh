#!/bin/bash -ex
#

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

if [ -f /etc/dogtag ] ; then
	cat /etc/dogtag
fi

if [ -b /dev/mmcblk0 ] ; then
	drive=/dev/mmcblk0
	test=$(dd if=${drive} count=6  skip=393248 bs=1 2>/dev/null || true)
	if [ "x${test}" = "xU-Boot" ] ; then
		dd if=${drive} count=32 skip=393248 bs=1 2>/dev/null
	fi
fi

if [ -b /dev/mmcblk1 ] ; then
	drive=/dev/mmcblk1
	test=$(dd if=${drive} count=6  skip=393248 bs=1 2>/dev/null || true)
	if [ "x${test}" = "xU-Boot" ] ; then
		dd if=${drive} count=32 skip=393248 bs=1 2>/dev/null
	fi
fi

uname -r

