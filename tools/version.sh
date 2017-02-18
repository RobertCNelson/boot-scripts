#!/bin/sh -e
#

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

git_bin=$(which git)

if [ -f ${git_bin} ] ; then
	if [ -d /opt/scripts/ ] ; then
		cd /opt/scripts/
		echo "git:/opt/scripts/:[$(${git_bin} rev-parse HEAD)]"
		cd -
	fi
fi

if [ -f /etc/dogtag ] ; then
	echo "dogtag:[`cat /etc/dogtag`]"
fi

if [ -b /dev/mmcblk0 ] ; then
	drive=/dev/mmcblk0
	test=$(dd if=${drive} count=6  skip=393248 bs=1 2>/dev/null || true)
	if [ "x${test}" = "xU-Boot" ] ; then
		uboot=$(dd if=${drive} count=32 skip=393248 bs=1 2>/dev/null || true)
		echo "bootloader on ${drive}:[${uboot}]"
	fi
fi

if [ -b /dev/mmcblk1 ] ; then
	drive=/dev/mmcblk1
	test=$(dd if=${drive} count=6  skip=393248 bs=1 2>/dev/null || true)
	if [ "x${test}" = "xU-Boot" ] ; then
		uboot=$(dd if=${drive} count=32 skip=393248 bs=1 2>/dev/null || true)
		echo "bootloader on ${drive}:[${uboot}]"
	fi
fi

echo "kernel:[`uname -r`]"

if [ -f /usr/bin/nodejs ] ; then
	echo "nodejs:[`/usr/bin/nodejs --version`]"
fi
