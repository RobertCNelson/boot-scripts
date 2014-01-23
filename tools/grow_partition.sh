#!/bin/sh -e
#
# Copyright (c) 2014 Robert Nelson <robertcnelson@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

unset boot_drive
boot_drive=$(LC_ALL=C lsblk -l | grep "/boot/uboot" | awk '{print $1}')

if [ "x${boot_drive}" = "x" ] ; then
	echo "Error: script halting, system unrecognized..."
	exit 1
fi

if [ "x${boot_drive}" = "xmmcblk0p1" ] ; then
	drive="/dev/mmcblk0"
elif [ "x${boot_drive}" = "xmmcblk1p1" ] ; then
	drive="/dev/mmcblk1"
else
	echo "Error: script halting, could detect drive..."
	exit 1
fi

backup_partition () {
	echo "sfdisk: backing up partition layout."
	sfdisk -d ${drive} > /etc/sfdisk.backup
}

expand_partition () {
	echo "sfdisk: initial calculation."
	#sfdisk -N2 --force --no-reread /dev/mmcblk0 <<-__EOF__
	#,,,-
	#__EOF__

	echo "${drive}" > /boot/uboot/resizerootfs
	echo "${drive}" > /resizerootfs

	sfdisk --force --no-reread --in-order --Linux --unit M ${drive} <<-__EOF__
	1,96,0xE,*
	,,,-
	__EOF__
}

restore_partition () {
	echo "sfdisk: restoring original layout"
	sfdisk --force ${drive} < /etc/sfdisk.backup
}

backup_partition
expand_partition
echo "reboot"
#restore_partition
#
