#!/bin/bash -e
#
# Copyright (c) 2013-2016 Robert Nelson <robertcnelson@gmail.com>
# Portions copyright (c) 2014 Charles Steinkuehler <charles@steinkuehler.net>
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

#This script assumes, these packages are installed, as network may not be setup
#dosfstools initramfs-tools rsync u-boot-tools

source $(dirname "$0")/functions.sh

device_eeprom="bbbw-eeprom"

check_if_run_as_root
find_root_drive

boot_drive="${root_drive%?}1"

if [ ! "x${boot_drive}" = "x${root_drive}" ] ; then
	mount ${boot_drive} /boot/uboot -o ro
fi
mount -t tmpfs tmpfs /tmp

if [ "x${boot_drive}" = "x/dev/mmcblk0p1" ] ; then
	source="/dev/mmcblk0"
	destination="/dev/mmcblk1"
fi

if [ "x${boot_drive}" = "x/dev/mmcblk1p1" ] ; then
	source="/dev/mmcblk1"
	destination="/dev/mmcblk0"
fi

#We override the copy_rootfs that comes from functions.sh as this one has wireless added to it
copy_rootfs () {
	message="Copying: ${source}p${media_rootfs} -> ${destination}p${media_rootfs}" ; broadcast
	mkdir -p /tmp/rootfs/ || true

	mount ${destination}p${media_rootfs} /tmp/rootfs/ -o async,noatime

	message="rsync: / -> /tmp/rootfs/" ; broadcast
	rsync -aAx /* /tmp/rootfs/ --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found,/lib/modules/*,/uEnv.txt} || write_failure
	flush_cache

	if [ -d /tmp/rootfs/etc/ssh/ ] ; then
		#ssh keys will now get regenerated on the next bootup
		touch /tmp/rootfs/etc/ssh/ssh.regenerate
		flush_cache
	fi

	mkdir -p /tmp/rootfs/lib/modules/$(uname -r)/ || true

	message="Copying: Kernel modules" ; broadcast
	message="rsync: /lib/modules/$(uname -r)/ -> /tmp/rootfs/lib/modules/$(uname -r)/" ; broadcast
	rsync -aAx /lib/modules/$(uname -r)/* /tmp/rootfs/lib/modules/$(uname -r)/ || write_failure
	flush_cache

	message="Copying: ${source}p${media_rootfs} -> ${destination}p${media_rootfs} complete" ; broadcast
	message="-----------------------------" ; broadcast

	message="Final System Tweaks:" ; broadcast

	unset root_uuid
	root_uuid=$(/sbin/blkid -c /dev/null -s UUID -o value ${destination}p${media_rootfs})
	if [ "${root_uuid}" ] ; then
		sed -i -e 's:uuid=:#uuid=:g' /tmp/rootfs/boot/uEnv.txt
		echo "uuid=${root_uuid}" >> /tmp/rootfs/boot/uEnv.txt

		message="UUID=${root_uuid}" ; broadcast
		root_uuid="UUID=${root_uuid}"
	else
		#really a failure...
		root_uuid="${source}p${media_rootfs}"
	fi

	message="Generating: /etc/fstab" ; broadcast
	echo "# /etc/fstab: static file system information." > /tmp/rootfs/etc/fstab
	echo "#" >> /tmp/rootfs/etc/fstab
	echo "${root_uuid}  /  ext4  noatime,errors=remount-ro  0  1" >> /tmp/rootfs/etc/fstab
	echo "debugfs  /sys/kernel/debug  debugfs  defaults  0  0" >> /tmp/rootfs/etc/fstab
	cat /tmp/rootfs/etc/fstab

	message="/boot/uEnv.txt: disabling eMMC flasher script" ; broadcast
	sed -i -e 's:'$emmcscript':#'$emmcscript':g' /tmp/rootfs/boot/uEnv.txt
	cat /tmp/rootfs/boot/uEnv.txt
	message="-----------------------------" ; broadcast

	flush_cache
	message="running: chroot /tmp/rootfs/ /usr/bin/bb-wl18xx-wlan0" ; broadcast

	mount --bind /proc /tmp/rootfs/proc
	mount --bind /sys /tmp/rootfs/sys
	mount --bind /dev /tmp/rootfs/dev
	mount --bind /dev/pts /tmp/rootfs/dev/pts

	modprobe wl18xx
	message="-----------------------------" ; broadcast
	message="lsmod" ; broadcast
	message="`lsmod`" ; broadcast
	message="-----------------------------" ; broadcast
	chroot /tmp/rootfs/ /usr/bin/bb-wl18xx-wlan0
	message="-----------------------------" ; broadcast

	flush_cache
	message="initrd: `ls -lh /tmp/rootfs/boot/initrd.img*`" ; broadcast

	umount -fl /tmp/rootfs/dev/pts
	umount -fl /tmp/rootfs/dev
	umount -fl /tmp/rootfs/proc
	umount -fl /tmp/rootfs/sys
	sleep 2

	flush_cache
	message="-----------------------------" ; broadcast
	umount /tmp/rootfs/ || umount -l /tmp/rootfs/ || write_failure

	if [ "x${is_bbb}" = "xenable" ] ; then
		[ -e /proc/$CYLON_PID ]  && kill $CYLON_PID
	fi

	message="Syncing: ${destination}" ; broadcast
	#https://github.com/beagleboard/meta-beagleboard/blob/master/contrib/bone-flash-tool/emmc.sh#L158-L159
	# force writeback of eMMC buffers
	sync
	dd if=${destination} of=/dev/null count=100000
	message="Syncing: ${destination} complete" ; broadcast
	message="-----------------------------" ; broadcast

	if [ -f /boot/debug.txt ] ; then
		message="This script has now completed its task" ; broadcast
		message="-----------------------------" ; broadcast
		message="debug: enabled" ; broadcast
		inf_loop
	else
		umount /tmp || umount -l /tmp
		if [ "x${is_bbb}" = "xenable" ] ; then
			if [ -e /sys/class/leds/beaglebone\:green\:usr0/trigger ] ; then
				echo default-on > /sys/class/leds/beaglebone\:green\:usr0/trigger
				echo default-on > /sys/class/leds/beaglebone\:green\:usr1/trigger
				echo default-on > /sys/class/leds/beaglebone\:green\:usr2/trigger
				echo default-on > /sys/class/leds/beaglebone\:green\:usr3/trigger
			fi
		fi
		mount

		message="eMMC has been flashed: please wait for device to power down." ; broadcast
		message="-----------------------------" ; broadcast

		flush_cache
		#To properly shudown, /opt/scripts/boot/am335x_evm.sh is going to call halt:
		exec /sbin/init
	fi
}

sleep 5
startup_message
get_device
check_eeprom
check_running_system
activate_cylon_leds
partition_drive
#
