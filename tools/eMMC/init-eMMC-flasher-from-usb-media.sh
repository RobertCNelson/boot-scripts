#!/bin/bash -e
#
# Copyright (c) 2013-2015 Robert Nelson <robertcnelson@gmail.com>
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

#WARNING make sure to run this with an initrd...
#lsmod:
#Module                  Size  Used by
#uas                    14300  0 
#usb_storage            53318  1 uas

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

unset root_drive
root_drive="$(cat /proc/cmdline | sed 's/ /\n/g' | grep root=UUID= | awk -F 'root=' '{print $2}' || true)"
if [ ! "x${root_drive}" = "x" ] ; then
	root_drive="$(/sbin/findfs ${root_drive} || true)"
else
	root_drive="$(cat /proc/cmdline | sed 's/ /\n/g' | grep root= | awk -F 'root=' '{print $2}' || true)"
fi

mount -t tmpfs tmpfs /tmp

destination="/dev/mmcblk1"
usb_drive="/dev/sda"

flush_cache () {
	sync
	blockdev --flushbufs ${destination}
}

broadcast () {
	if [ "x${message}" != "x" ] ; then
		echo "${message}"
		echo "${message}" > /dev/tty0 || true
	fi
}

inf_loop () {
	while read MAGIC ; do
		case $MAGIC in
		beagleboard.org)
			echo "Your foo is strong!"
			bash -i
			;;
		*)	echo "Your foo is weak."
			;;
		esac
	done
}

# umount does not like device names without a valid /etc/mtab
# find the mount point from /proc/mounts
dev2dir () {
	grep -m 1 '^$1 ' /proc/mounts | while read LINE ; do set -- $LINE ; echo $2 ; done
}

write_failure () {
	message="writing to [${destination}] failed..." ; broadcast

	[ -e /proc/$CYLON_PID ]  && kill $CYLON_PID > /dev/null 2>&1

	if [ -e /sys/class/leds/beaglebone\:green\:usr0/trigger ] ; then
		echo heartbeat > /sys/class/leds/beaglebone\:green\:usr0/trigger
		echo heartbeat > /sys/class/leds/beaglebone\:green\:usr1/trigger
		echo heartbeat > /sys/class/leds/beaglebone\:green\:usr2/trigger
		echo heartbeat > /sys/class/leds/beaglebone\:green\:usr3/trigger
	fi
	message="-----------------------------" ; broadcast
	flush_cache
	inf_loop
}

print_eeprom () {
	unset got_eeprom

	#v8 of nvmem...
	if [ -f /sys/bus/nvmem/devices/at24-0/nvmem ] && [ "x${got_eeprom}" = "x" ] ; then
		eeprom="/sys/bus/nvmem/devices/at24-0/nvmem"

		#eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -s 5 -n 3) = blank...
		#hexdump -e '8/1 "%c"' ${eeprom} -n 8 = �U3�A335
		eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -n 28 | cut -b 5-28)

		eeprom_location="/sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/at24-0/nvmem"
		got_eeprom="true"
	fi

	#pre-v8 of nvmem...
	if [ -f /sys/class/nvmem/at24-0/nvmem ] && [ "x${got_eeprom}" = "x" ] ; then
		eeprom="/sys/class/nvmem/at24-0/nvmem"

		#with 4.1.x: -s 5 isn't working...
		#eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -s 5 -n 3) = blank...
		#hexdump -e '8/1 "%c"' ${eeprom} -n 8 = �U3�A335
		eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -n 28 | cut -b 5-28)

		eeprom_location="/sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/nvmem/at24-0/nvmem"
		got_eeprom="true"
	fi

	#eeprom...
	if [ -f /sys/bus/i2c/devices/0-0050/eeprom ] && [ "x${got_eeprom}" = "x" ] ; then
		eeprom="/sys/bus/i2c/devices/0-0050/eeprom"
		eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -s 5 -n 25)
		eeprom_location=$(ls /sys/devices/ocp*/44e0b000.i2c/i2c-0/0-0050/eeprom 2> /dev/null)
		got_eeprom="true"
	fi

	if [ "x${got_eeprom}" = "xtrue" ] ; then
		message="EEPROM: [${eeprom_header}]" ; broadcast
		message="-----------------------------" ; broadcast
	fi
}

flash_emmc () {
	if [ ! "x${conf_bmap}" = "x" ] ; then
		if [ -f /usr/bin/bmaptool ] && [ -f /tmp/usb/${conf_bmap} ] ; then
			message="Flashing eMMC with bmaptool" ; broadcast
			message="-----------------------------" ; broadcast
			message="bmaptool copy --bmap /tmp/usb/${conf_bmap} /tmp/usb/${conf_image} ${destination}" ; broadcast
			/usr/bin/bmaptool copy --bmap /tmp/usb/${conf_bmap} /tmp/usb/${conf_image} ${destination} || write_failure
			message="-----------------------------" ; broadcast
		else
			message="Flashing eMMC with dd" ; broadcast
			message="-----------------------------" ; broadcast
			message="xzcat /tmp/usb/${conf_image} | dd of=${destination} bs=1M" ; broadcast
			xzcat /tmp/usb/${conf_image} | dd of=${destination} bs=1M || write_failure
			message="-----------------------------" ; broadcast
		fi
	else
		message="Flashing eMMC with dd" ; broadcast
		message="-----------------------------" ; broadcast
		message="xzcat /tmp/usb/${conf_image} | dd of=${destination} bs=1M" ; broadcast
		xzcat /tmp/usb/${conf_image} | dd of=${destination} bs=1M || write_failure
		message="-----------------------------" ; broadcast
	fi
	flush_cache
}

auto_fsck () {
	message="-----------------------------" ; broadcast
	if [ "x${conf_partition1_fstype}" = "x0x83" ] ; then
		message="e2fsck -f -p ${destination}p1" ; broadcast
		e2fsck -f -p ${destination}p1
		message="-----------------------------" ; broadcast
	fi
	if [ "x${conf_partition2_fstype}" = "x0x83" ] ; then
		message="e2fsck -f -p ${destination}p2" ; broadcast
		e2fsck -f -p ${destination}p2
		message="-----------------------------" ; broadcast
	fi
	if [ "x${conf_partition3_fstype}" = "x0x83" ] ; then
		message="e2fsck -f -p ${destination}p3" ; broadcast
		e2fsck -f -p ${destination}p3
		message="-----------------------------" ; broadcast
	fi
	if [ "x${conf_partition4_fstype}" = "x0x83" ] ; then
		message="e2fsck -f -p ${destination}p4" ; broadcast
		e2fsck -f -p ${destination}p4
		message="-----------------------------" ; broadcast
	fi
	flush_cache
}

quad_partition () {
	message="LC_ALL=C sfdisk --force --no-reread --in-order --Linux --unit M ${destination}" ; broadcast
	message="${conf_partition1_startmb},${conf_partition1_endmb},${conf_partition1_fstype},*" ; broadcast
	message=",${conf_partition2_endmb},${conf_partition2_fstype},-" ; broadcast
	message=",${conf_partition3_endmb},${conf_partition3_fstype},-" ; broadcast
	message=",,${conf_partition4_fstype},-" ; broadcast
	message="-----------------------------" ; broadcast

	LC_ALL=C sfdisk --force --no-reread --in-order --Linux --unit M ${destination} <<-__EOF__
		${conf_partition1_startmb},${conf_partition1_endmb},${conf_partition1_fstype},*
		,${conf_partition2_endmb},${conf_partition2_fstype},-
		,${conf_partition3_endmb},${conf_partition3_fstype},-
		,,${conf_partition4_fstype},-
	__EOF__

	auto_fsck
	message="resize2fs ${destination}p4" ; broadcast
	resize2fs ${destination}p4
	message="-----------------------------" ; broadcast
}

tri_partition () {
	message="LC_ALL=C sfdisk --force --no-reread --in-order --Linux --unit M ${destination}" ; broadcast
	message="${conf_partition1_startmb},${conf_partition1_endmb},${conf_partition1_fstype},*" ; broadcast
	message=",${conf_partition2_endmb},${conf_partition2_fstype},-" ; broadcast
	message=",,${conf_partition3_fstype},-" ; broadcast
	message="-----------------------------" ; broadcast

	LC_ALL=C sfdisk --force --no-reread --in-order --Linux --unit M ${destination} <<-__EOF__
		${conf_partition1_startmb},${conf_partition1_endmb},${conf_partition1_fstype},*
		,${conf_partition2_endmb},${conf_partition2_fstype},-
		,,${conf_partition3_fstype},-
	__EOF__

	auto_fsck
	message="resize2fs ${destination}p3" ; broadcast
	resize2fs ${destination}p3
	message="-----------------------------" ; broadcast
}

dual_partition () {
	message="LC_ALL=C sfdisk --force --no-reread --in-order --Linux --unit M ${destination}" ; broadcast
	message="${conf_partition1_startmb},${conf_partition1_endmb},${conf_partition1_fstype},*" ; broadcast
	message=",,${conf_partition2_fstype},-" ; broadcast
	message="-----------------------------" ; broadcast

	LC_ALL=C sfdisk --force --no-reread --in-order --Linux --unit M ${destination} <<-__EOF__
		${conf_partition1_startmb},${conf_partition1_endmb},${conf_partition1_fstype},*
		,,${conf_partition2_fstype},-
	__EOF__

	auto_fsck
	message="resize2fs ${destination}p2" ; broadcast
	resize2fs ${destination}p2
	message="-----------------------------" ; broadcast
}

single_partition () {
	message="LC_ALL=C sfdisk --force --no-reread --in-order --Linux --unit M ${destination}" ; broadcast
	message="${conf_partition1_startmb},${conf_partition1_endmb},${conf_partition1_fstype},*" ; broadcast
	message="-----------------------------" ; broadcast

	LC_ALL=C sfdisk --force --no-reread --in-order --Linux --unit M ${destination} <<-__EOF__
		${conf_partition1_startmb},,${conf_partition1_fstype},*
	__EOF__

	auto_fsck
	message="resize2fs ${destination}p1" ; broadcast
	resize2fs ${destination}p1
	message="-----------------------------" ; broadcast
}

resize_emmc () {
	unset resized

	conf_partition1_startmb=$(cat /tmp/usb/job.txt | grep -v '#' | grep conf_partition1_startmb | awk -F '=' '{print $2}' || true)
	conf_partition1_fstype=$(cat /tmp/usb/job.txt | grep -v '#' | grep conf_partition1_fstype | awk -F '=' '{print $2}' || true)
	conf_partition1_endmb=$(cat /tmp/usb/job.txt | grep -v '#' | grep conf_partition1_endmb | awk -F '=' '{print $2}' || true)

	conf_partition2_fstype=$(cat /tmp/usb/job.txt | grep -v '#' | grep conf_partition2_fstype | awk -F '=' '{print $2}' || true)
	conf_partition2_endmb=$(cat /tmp/usb/job.txt | grep -v '#' | grep conf_partition2_endmb | awk -F '=' '{print $2}' || true)

	conf_partition3_fstype=$(cat /tmp/usb/job.txt | grep -v '#' | grep conf_partition3_fstype | awk -F '=' '{print $2}' || true)
	conf_partition3_endmb=$(cat /tmp/usb/job.txt | grep -v '#' | grep conf_partition3_endmb | awk -F '=' '{print $2}' || true)

	conf_partition4_fstype=$(cat /tmp/usb/job.txt | grep -v '#' | grep conf_partition4_fstype | awk -F '=' '{print $2}' || true)

	if [ ! "x${conf_partition4_fstype}" = "x" ] ; then
		quad_partition
		resized="done"
	fi

	if [ ! "x${conf_partition3_fstype}" = "x" ] && [ ! "x${resized}" = "xdone" ] ; then
		tri_partition
		resized="done"
	fi

	if [ ! "x${conf_partition2_fstype}" = "x" ] && [ ! "x${resized}" = "xdone" ] ; then
		dual_partition
		resized="done"
	fi

	if [ ! "x${conf_partition1_fstype}" = "x" ] && [ ! "x${resized}" = "xdone" ] ; then
		single_partition
		resized="done"
	fi
	flush_cache
}

set_uuid () {
	unset root_uuid
	root_uuid=$(/sbin/blkid -c /dev/null -s UUID -o value ${destination}p${conf_root_partition} || true)
	mkdir -p /tmp/rootfs/
	mkdir -p /tmp/boot/

	mount ${destination}p${conf_root_partition} /tmp/rootfs/ -o async,noatime
	sleep 2

	if [ ! "x${conf_root_partition}" = "x1" ] ; then
		mount ${destination}p1 /tmp/boot/ -o sync
		sleep 2
	fi

	if [ -f /tmp/rootfs/boot/uEnv.txt ] && [ -f /tmp/boot/uEnv.txt ] ; then
		rm -f /tmp/boot/uEnv.txt
		umount /tmp/boot/ || umount -l /tmp/boot/ || write_failure
	fi

	if [ -f /tmp/rootfs/boot/uEnv.txt ] && [ -f /tmp/rootfs/uEnv.txt ] ; then
		rm -f /tmp/rootfs/uEnv.txt
	fi

	unset uuid_uevntxt
	uuid_uevntxt=$(cat /tmp/rootfs/boot/uEnv.txt | grep -v '#' | grep uuid | awk -F '=' '{print $2}' || true)
	if [ ! "x${uuid_uevntxt}" = "x" ] ; then
		sed -i -e "s:uuid=$uuid_uevntxt:uuid=$root_uuid:g" /tmp/rootfs/boot/uEnv.txt
	else
		sed -i -e "s:#uuid=:uuid=$root_uuid:g" /tmp/rootfs/boot/uEnv.txt
		unset uuid_uevntxt
		uuid_uevntxt=$(cat /tmp/rootfs/boot/uEnv.txt | grep -v '#' | grep uuid | awk -F '=' '{print $2}' || true)
		if [ "x${uuid_uevntxt}" = "x" ] ; then
			echo "uuid=${root_uuid}" >> /tmp/rootfs/boot/uEnv.txt
		fi
	fi

	unset uuid_uevntxt
	uuid_uevntxt=$(cat /tmp/rootfs/boot/uEnv.txt | grep -v '#' | grep cmdline | awk -F '=' '{print $2}' || true)
	if [ ! "x${uuid_uevntxt}" = "x" ] ; then
		sed -i -e "s:cmdline=init:#cmdline=init:g" /tmp/rootfs/boot/uEnv.txt
	fi

	message="`cat /tmp/rootfs/boot/uEnv.txt | grep uuid`" ; broadcast
	message="-----------------------------" ; broadcast
	flush_cache

	message="UUID=${root_uuid}" ; broadcast
	root_uuid="UUID=${root_uuid}"

	message="Generating: /etc/fstab" ; broadcast
	echo "# /etc/fstab: static file system information." > /tmp/rootfs/etc/fstab
	echo "#" >> /tmp/rootfs/etc/fstab
	echo "${root_uuid}  /  ext4  noatime,errors=remount-ro  0  1" >> /tmp/rootfs/etc/fstab
	echo "debugfs  /sys/kernel/debug  debugfs  defaults  0  0" >> /tmp/rootfs/etc/fstab
	message="`cat /tmp/rootfs/etc/fstab`" ; broadcast
	message="-----------------------------" ; broadcast
	flush_cache

	umount /tmp/rootfs/ || umount -l /tmp/rootfs/ || write_failure
}

check_eeprom () {
	unset got_eeprom

	#v8 of nvmem...
	if [ -f /sys/bus/nvmem/devices/at24-0/nvmem ] && [ "x${got_eeprom}" = "x" ] ; then
		eeprom="/sys/bus/nvmem/devices/at24-0/nvmem"

		#eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -s 5 -n 3) = blank...
		#hexdump -e '8/1 "%c"' ${eeprom} -n 8 = �U3�A335
		eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -n 8 | cut -b 6-8)

		eeprom_location="/sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/at24-0/nvmem"
		got_eeprom="true"
	fi

	#pre-v8 of nvmem...
	if [ -f /sys/class/nvmem/at24-0/nvmem ] && [ "x${got_eeprom}" = "x" ] ; then
		eeprom="/sys/class/nvmem/at24-0/nvmem"

		#with 4.1.x: -s 5 isn't working...
		#eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -s 5 -n 3) = blank...
		#hexdump -e '8/1 "%c"' ${eeprom} -n 8 = �U3�A335
		eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -n 8 | cut -b 6-8)

		eeprom_location="/sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/nvmem/at24-0/nvmem"
		got_eeprom="true"
	fi

	#eeprom...
	if [ -f /sys/bus/i2c/devices/0-0050/eeprom ] && [ "x${got_eeprom}" = "x" ] ; then
		eeprom="/sys/bus/i2c/devices/0-0050/eeprom"
		eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -s 5 -n 3)
		eeprom_location=$(ls /sys/devices/ocp*/44e0b000.i2c/i2c-0/0-0050/eeprom 2> /dev/null)
		got_eeprom="true"
	fi

	if [ "x${got_eeprom}" = "xtrue" ] ; then
		if [ "x${eeprom_header}" = "x${conf_eeprom_compare}" ] ; then
			message="Valid EEPROM header found [${eeprom_header}]" ; broadcast
			message="-----------------------------" ; broadcast
		else
			message="Invalid EEPROM header detected" ; broadcast
			if [ ! "x${eeprom_location}" = "x" ] ; then
				message="Writing header to EEPROM" ; broadcast
				dd if=/tmp/usb/${conf_eeprom_file} of=${eeprom_location} || write_failure
				sync
				sync
				eeprom_check=$(hexdump -e '8/1 "%c"' ${eeprom} -n 8 | cut -b 6-8)
				echo "eeprom check: [${eeprom_check}]"

				#We have to reboot, as the kernel only loads the eMMC cape
				# with a valid header
				reboot -f

				#We shouldnt hit this...
				exit
			fi
		fi
	fi
}

cylon_leds () {
	if [ -e /sys/class/leds/beaglebone\:green\:usr0/trigger ] ; then
		BASE=/sys/class/leds/beaglebone\:green\:usr
		echo none > ${BASE}0/trigger
		echo none > ${BASE}1/trigger
		echo none > ${BASE}2/trigger
		echo none > ${BASE}3/trigger

		STATE=1
		while : ; do
			case $STATE in
			1)	echo 255 > ${BASE}0/brightness
				echo 0   > ${BASE}1/brightness
				STATE=2
				;;
			2)	echo 255 > ${BASE}1/brightness
				echo 0   > ${BASE}0/brightness
				STATE=3
				;;
			3)	echo 255 > ${BASE}2/brightness
				echo 0   > ${BASE}1/brightness
				STATE=4
				;;
			4)	echo 255 > ${BASE}3/brightness
				echo 0   > ${BASE}2/brightness
				STATE=5
				;;
			5)	echo 255 > ${BASE}2/brightness
				echo 0   > ${BASE}3/brightness
				STATE=6
				;;
			6)	echo 255 > ${BASE}1/brightness
				echo 0   > ${BASE}2/brightness
				STATE=1
				;;
			*)	echo 255 > ${BASE}0/brightness
				echo 0   > ${BASE}1/brightness
				STATE=2
				;;
			esac
			sleep 0.1
		done
	fi
}


process_job_file () {
	job_file=found
	message="Processing job.txt:" ; broadcast
	message="`cat /tmp/usb/job.txt | grep -v '#'`" ; broadcast
	message="-----------------------------" ; broadcast

	abi=$(cat /tmp/usb/job.txt | grep -v '#' | grep abi | awk -F '=' '{print $2}' || true)
	if [ "x${abi}" = "xaaa" ] ; then
		conf_eeprom_file=$(cat /tmp/usb/job.txt | grep -v '#' | grep conf_eeprom_file | awk -F '=' '{print $2}' || true)
		conf_eeprom_compare=$(cat /tmp/usb/job.txt | grep -v '#' | grep conf_eeprom_compare | awk -F '=' '{print $2}' || true)
		if [ -f /tmp/usb/${conf_eeprom_file} ] ; then
			check_eeprom
		fi

		conf_image=$(cat /tmp/usb/job.txt | grep -v '#' | grep conf_image | awk -F '=' '{print $2}' || true)
		if [ -f /tmp/usb/${conf_image} ] ; then
			conf_bmap=$(cat /tmp/usb/job.txt | grep -v '#' | grep conf_bmap | awk -F '=' '{print $2}' || true)
			cylon_leds & CYLON_PID=$!
			flash_emmc
			conf_resize=$(cat /tmp/usb/job.txt | grep -v '#' | grep conf_resize | awk -F '=' '{print $2}' || true)
			if [ "x${conf_resize}" = "xenable" ] ; then
				message="resizing eMMC" ; broadcast
				message="-----------------------------" ; broadcast
				resize_emmc
			fi
			conf_root_partition=$(cat /tmp/usb/job.txt | grep -v '#' | grep conf_root_partition | awk -F '=' '{print $2}' || true)
			if [ ! "x${conf_root_partition}" = "x" ] ; then
				set_uuid
			fi
			[ -e /proc/$CYLON_PID ]  && kill $CYLON_PID
		else
			message="error: image not found [/tmp/usb/${conf_image}]" ; broadcast
		fi
	fi
}

check_usb_media () {
	message="Checking external usb media" ; broadcast
	message="lsblk:" ; broadcast
	message="`lsblk || true`" ; broadcast
	message="-----------------------------" ; broadcast

	if [ ! -e /sys/class/leds/beaglebone\:green\:usr0/trigger ] ; then
		modprobe leds_gpio || true
		sleep 1
	fi

	unset job_file

	num_partitions=$(LC_ALL=C fdisk -l 2>/dev/null | grep "^${usb_drive}" | grep -v "Extended" | grep -v "swap" | wc -l)

	i=0 ; while test $i -le ${num_partitions} ; do
		partition=$(LC_ALL=C fdisk -l 2>/dev/null | grep "^${usb_drive}" | grep -v "Extended" | grep -v "swap" | head -${i} | tail -1 | awk '{print $1}')
		if [ ! "x${partition}" = "x" ] ; then
			message="Trying: [${partition}]" ; broadcast

			mkdir -p "/tmp/usb/"
			mount ${partition} "/tmp/usb/" -o ro

			sync ; sync ; sleep 5

			if [ ! -f /tmp/usb/job.txt ] ; then
				umount "/tmp/usb/" || true
			else
				process_job_file
			fi

		fi
	i=$(($i+1))
	done

	if [ ! "x${job_file}" = "xfound" ] ; then
		message="job.txt: format" ; broadcast
		message="-----------------------------" ; broadcast
		message="abi=aaa" ; broadcast
		message="conf_eeprom_file=<file>" ; broadcast
		message="conf_image=<file>.img.xz" ; broadcast
		message="conf_bmap=<file>.bmap" ; broadcast
		message="conf_resize=enable|<blank>" ; broadcast
		message="conf_partition1_startmb=1" ; broadcast
		message="conf_partition1_fstype=" ; broadcast

		message="#last endmb is ignored as it just uses the rest of the drive..." ; broadcast
		message="conf_partition1_endmb=" ; broadcast

		message="conf_partition2_fstype=" ; broadcast
		message="conf_partition2_endmb=" ; broadcast

		message="conf_partition3_fstype=" ; broadcast
		message="conf_partition3_endmb=" ; broadcast

		message="conf_partition4_fstype=" ; broadcast

		message="conf_root_partition=1|2|3|4" ; broadcast
		message="-----------------------------" ; broadcast
		write_failure
	fi

	message="eMMC has been flashed: please wait for device to power down." ; broadcast
	message="-----------------------------" ; broadcast

	umount /tmp || umount -l /tmp
	if [ -e /sys/class/leds/beaglebone\:green\:usr0/trigger ] ; then
		echo default-on > /sys/class/leds/beaglebone\:green\:usr0/trigger
		echo default-on > /sys/class/leds/beaglebone\:green\:usr1/trigger
		echo default-on > /sys/class/leds/beaglebone\:green\:usr2/trigger
		echo default-on > /sys/class/leds/beaglebone\:green\:usr3/trigger
	fi

	sleep 1

	#To properly shudown, /opt/scripts/boot/am335x_evm.sh is going to call halt:
	exec /sbin/init
	#halt -f
}

sleep 5
clear
message="-----------------------------" ; broadcast
message="Starting eMMC Flasher from usb media" ; broadcast
message="-----------------------------" ; broadcast

print_eeprom
check_usb_media
#
