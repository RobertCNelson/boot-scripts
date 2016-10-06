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

#We override check_eeprom that come from functions.sh with this one
#The X15 seems different
check_eeprom () {
	device_eeprom="x15/X15_B1-eeprom"
	message="Checking for Valid ${device_eeprom} header" ; broadcast

	unset got_eeprom

	if [ -f /sys/bus/i2c/devices/0-0050/eeprom ] && [ "x${got_eeprom}" = "x" ] ; then
		eeprom="/sys/bus/i2c/devices/0-0050/eeprom"

		if [ -f /sys/devices/platform/44000000.ocp/48070000.i2c/i2c-0/0-0050/eeprom ] ; then
			eeprom_location="/sys/devices/platform/44000000.ocp/48070000.i2c/i2c-0/0-0050/eeprom"
		fi

		got_eeprom="true"
	fi

	if [ "x${got_eeprom}" = "xtrue" ] ; then
		eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -n 3 | cut -b 2-3)
		if [ "x${eeprom_header}" = "xU3" ] ; then
			message="Valid ${device_eeprom} header found [${eeprom_header}]" ; broadcast
			message="-----------------------------" ; broadcast
		else
			message="Invalid EEPROM header detected" ; broadcast
			if [ -f /opt/scripts/device/${device_eeprom}.dump ] ; then
				if [ ! "x${eeprom_location}" = "x" ] ; then
					message="Writing header to EEPROM" ; broadcast
					dd if=/opt/scripts/device/${device_eeprom}.dump of=${eeprom_location}
					sync
					sync
					eeprom_check=$(hexdump -e '8/1 "%c"' ${eeprom} -n 3 | cut -b 2-3)
					echo "eeprom check: [${eeprom_check}]"

					#We have to reboot, as the kernel only loads the eMMC cape
					# with a valid header
					reboot -f

					#We shouldnt hit this...
					exit
				fi
			else
				message="error: no [/opt/scripts/device/${device_eeprom}.dump]" ; broadcast
			fi
		fi
	fi
}

#We override copy_rootfs from functions.sh as the x15 seems different
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
	root_uuid="${destination}p${media_rootfs}"

#	root_uuid=$(/sbin/blkid -c /dev/null -s PARTUUID -o value ${destination}p${media_rootfs})
#	if [ ! "x${root_uuid}" = "x" ] ; then
#		sed -i -e 's:uuid=:#uuid=:g' /tmp/rootfs/boot/uEnv.txt
#		message="PARTUUID=${root_uuid}" ; broadcast
#		root_uuid="PARTUUID=${root_uuid}"
#	else
#		unset root_uuid
#		root_uuid=$(/sbin/blkid -c /dev/null -s UUID -o value ${destination}p${media_rootfs})
#		if [ "${root_uuid}" ] ; then
#			sed -i -e 's:uuid=:#uuid=:g' /tmp/rootfs/boot/uEnv.txt
#			echo "uuid=${root_uuid}" >> /tmp/rootfs/boot/uEnv.txt

#			message="UUID=${root_uuid}" ; broadcast
#			root_uuid="UUID=${root_uuid}"
#		else
#			#really a failure...
#			root_uuid="${source}p${media_rootfs}"
#		fi
#	fi

	message="Generating: /etc/fstab" ; broadcast
	echo "# /etc/fstab: static file system information." > /tmp/rootfs/etc/fstab
	echo "#" >> /tmp/rootfs/etc/fstab
	echo "${root_uuid}  /  ext4  noatime,errors=remount-ro  0  1" >> /tmp/rootfs/etc/fstab
	echo "debugfs  /sys/kernel/debug  debugfs  defaults  0  0" >> /tmp/rootfs/etc/fstab
	cat /tmp/rootfs/etc/fstab

	message="/boot/uEnv.txt: disabling eMMC flasher script" ; broadcast
	script="cmdline=init=/opt/scripts/tools/eMMC/init-eMMC-flasher-v3-x15_b1.sh"
	sed -i -e 's:'$script':#'$script':g' /tmp/rootfs/boot/uEnv.txt
	cat /tmp/rootfs/boot/uEnv.txt
	message="-----------------------------" ; broadcast

	flush_cache
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
