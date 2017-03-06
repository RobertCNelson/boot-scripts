#!/bin/sh -e
#

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

git_bin=$(which git)

omap_bootloader () {
	unset test_var
	test_var=$(dd if=${drive} count=6 skip=393248 bs=1 2>/dev/null || true)
	if [ "x${test_var}" = "xU-Boot" ] ; then
		uboot=$(dd if=${drive} count=32 skip=393248 bs=1 2>/dev/null || true)
		uboot=$(echo ${uboot} | awk '{print $2}')
		echo "bootloader:[${drive}]:[U-Boot ${uboot}]"
		fi
	fi
}

if [ -f ${git_bin} ] ; then
	if [ -d /opt/scripts/ ] ; then
		old_dir="`pwd`"
		cd /opt/scripts/ || true
		echo "git:/opt/scripts/:[`${git_bin} rev-parse HEAD`]"
		cd "${old_dir}" || true
	fi
fi

if [ -f /sys/bus/i2c/devices/0-0050/eeprom ] ; then
	board_eeprom=$(hexdump -e '8/1 "%c"' /sys/bus/i2c/devices/0-0050/eeprom -n 28 | cut -b 5-28 || true)
	echo "eeprom:[${board_eeprom}]"
fi

if [ -f /etc/dogtag ] ; then
	echo "dogtag:[`cat /etc/dogtag`]"
fi

if [ -b /dev/mmcblk0 ] ; then
	drive=/dev/mmcblk0
	omap_bootloader
fi

if [ -b /dev/mmcblk1 ] ; then
	drive=/dev/mmcblk1
	omap_bootloader
fi

echo "kernel:[`uname -r`]"

if [ -f /usr/bin/nodejs ] ; then
	echo "nodejs:[`/usr/bin/nodejs --version`]"
fi
