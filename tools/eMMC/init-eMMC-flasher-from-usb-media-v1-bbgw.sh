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

version_message="1.20160618: deal with v4.4.x+ back to old eeprom location..."

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

get_device () {
	is_bbb="enable"
	machine=$(cat /proc/device-tree/model | sed "s/ /_/g")

	case "${machine}" in
	TI_AM5728_BeagleBoard-X15)
		unset is_bbb
		;;
	esac
}

write_failure () {
	message="writing to [${destination}] failed..." ; broadcast

	if [ "x${is_bbb}" = "xenable" ] ; then
		[ -e /proc/$CYLON_PID ]  && kill $CYLON_PID > /dev/null 2>&1

		if [ -e /sys/class/leds/beaglebone\:green\:usr0/trigger ] ; then
			echo heartbeat > /sys/class/leds/beaglebone\:green\:usr0/trigger
			echo heartbeat > /sys/class/leds/beaglebone\:green\:usr1/trigger
			echo heartbeat > /sys/class/leds/beaglebone\:green\:usr2/trigger
			echo heartbeat > /sys/class/leds/beaglebone\:green\:usr3/trigger
		fi
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
		eeprom_location="/sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/at24-0/nvmem"
		got_eeprom="true"
	fi

	#pre-v8 of nvmem...
	if [ -f /sys/class/nvmem/at24-0/nvmem ] && [ "x${got_eeprom}" = "x" ] ; then
		eeprom="/sys/class/nvmem/at24-0/nvmem"
		eeprom_location="/sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/nvmem/at24-0/nvmem"
		got_eeprom="true"
	fi

	#eeprom 3.8.x & 4.4 with eeprom-nvmem patchset...
	if [ -f /sys/bus/i2c/devices/0-0050/eeprom ] && [ "x${got_eeprom}" = "x" ] ; then
		eeprom="/sys/bus/i2c/devices/0-0050/eeprom"

		if [ -f /sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/eeprom ] ; then
			eeprom_location="/sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/eeprom"
		else
			eeprom_location=$(ls /sys/devices/ocp*/44e0b000.i2c/i2c-0/0-0050/eeprom 2> /dev/null)
		fi

		got_eeprom="true"
	fi

	if [ "x${got_eeprom}" = "xtrue" ] ; then
		eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -n 28 | cut -b 5-28)
		message="EEPROM: [${eeprom_header}]" ; broadcast
		message="-----------------------------" ; broadcast
	fi
}
dd_bootloader () {
	message="Writing bootloader to [${destination}]" ; broadcast

	unset dd_spl_uboot
	if [ ! "x${dd_spl_uboot_count}" = "x" ] ; then
		dd_spl_uboot="${dd_spl_uboot}count=${dd_spl_uboot_count} "
	fi

	if [ ! "x${dd_spl_uboot_seek}" = "x" ] ; then
		dd_spl_uboot="${dd_spl_uboot}seek=${dd_spl_uboot_seek} "
	fi

	if [ ! "x${dd_spl_uboot_conf}" = "x" ] ; then
		dd_spl_uboot="${dd_spl_uboot}conv=${dd_spl_uboot_conf} "
	fi

	if [ ! "x${dd_spl_uboot_bs}" = "x" ] ; then
		dd_spl_uboot="${dd_spl_uboot}bs=${dd_spl_uboot_bs}"
	fi

	unset dd_uboot
	if [ ! "x${dd_uboot_count}" = "x" ] ; then
		dd_uboot="${dd_uboot}count=${dd_uboot_count} "
	fi

	if [ ! "x${dd_uboot_seek}" = "x" ] ; then
		dd_uboot="${dd_uboot}seek=${dd_uboot_seek} "
	fi

	if [ ! "x${dd_uboot_conf}" = "x" ] ; then
		dd_uboot="${dd_uboot}conv=${dd_uboot_conf} "
	fi

	if [ ! "x${dd_uboot_bs}" = "x" ] ; then
		dd_uboot="${dd_uboot}bs=${dd_uboot_bs}"
	fi

	message="dd if=${dd_spl_uboot_backup} of=${destination} ${dd_spl_uboot}" ; broadcast
	echo "-----------------------------"
	dd if=${dd_spl_uboot_backup} of=${destination} ${dd_spl_uboot}
	echo "-----------------------------"
	message="dd if=${dd_uboot_backup} of=${destination} ${dd_uboot}" ; broadcast
	echo "-----------------------------"
	dd if=${dd_uboot_backup} of=${destination} ${dd_uboot}
	message="-----------------------------" ; broadcast
}
format_boot () {
	message="mkfs.vfat -F 16 ${destination}p1 -n ${boot_label}" ; broadcast
	echo "-----------------------------"
	mkfs.vfat -F 16 ${destination}p1 -n ${boot_label}
	echo "-----------------------------"
	flush_cache
}

format_root () {
	message="mkfs.ext4 ${destination}p2 -L ${rootfs_label}" ; broadcast
	echo "-----------------------------"
	mkfs.ext4 ${destination}p2 -L ${rootfs_label}
	echo "-----------------------------"
	flush_cache
}

format_single_root () {
	message="mkfs.ext4 ${destination}p1 -L ${boot_label}" ; broadcast
	echo "-----------------------------"
	mkfs.ext4 ${destination}p1 -L ${boot_label}
	echo "-----------------------------"
	flush_cache
}
partition_drive () {
	if [ -f /boot/SOC.sh ] ; then
		. /boot/SOC.sh
	fi

	dd_bootloader

	if [ "x${boot_fstype}" = "xfat" ] ; then
		conf_boot_startmb=${conf_boot_startmb:-"1"}
		conf_boot_endmb=${conf_boot_endmb:-"96"}
		sfdisk_fstype=${sfdisk_fstype:-"0xE"}
		boot_label=${boot_label:-"BEAGLEBONE"}
		rootfs_label=${rootfs_label:-"rootfs"}

		message="Formatting: ${destination}" ; broadcast

		sfdisk_options="--force --Linux --in-order --unit M"
		sfdisk_boot_startmb="${conf_boot_startmb}"
		sfdisk_boot_endmb="${conf_boot_endmb}"

		test_sfdisk=$(LC_ALL=C sfdisk --help | grep -m 1 -e "--in-order" || true)
		if [ "x${test_sfdisk}" = "x" ] ; then
			message="sfdisk: [2.26.x or greater]" ; broadcast
			sfdisk_options="--force"
			sfdisk_boot_startmb="${sfdisk_boot_startmb}M"
			sfdisk_boot_endmb="${sfdisk_boot_endmb}M"
		fi

		message="sfdisk: [sfdisk ${sfdisk_options} ${destination}]" ; broadcast
		message="sfdisk: [${sfdisk_boot_startmb},${sfdisk_boot_endmb},${sfdisk_fstype},*]" ; broadcast
		message="sfdisk: [,,,-]" ; broadcast

		LC_ALL=C sfdisk ${sfdisk_options} "${destination}" <<-__EOF__
			${sfdisk_boot_startmb},${sfdisk_boot_endmb},${sfdisk_fstype},*
			,,,-
		__EOF__

		flush_cache
		format_boot
		format_root
		message="Formatting: ${destination} complete" ; broadcast
		message="-----------------------------" ; broadcast

		copy_boot
		media_rootfs="2"
	else
		conf_boot_startmb=${conf_boot_startmb:-"1"}
		sfdisk_fstype=${sfdisk_fstype:-"L"}
		if [ "x${sfdisk_fstype}" = "x0x83" ] ; then
			sfdisk_fstype="L"
		fi
		boot_label=${boot_label:-"BEAGLEBONE"}

		message="Formatting: ${destination}" ; broadcast

		sfdisk_options="--force --Linux --in-order --unit M"
		sfdisk_boot_startmb="${conf_boot_startmb}"

		test_sfdisk=$(LC_ALL=C sfdisk --help | grep -m 1 -e "--in-order" || true)
		if [ "x${test_sfdisk}" = "x" ] ; then
			message="sfdisk: [2.26.x or greater]" ; broadcast
			if [ "x${bootrom_gpt}" = "xenable" ] ; then
				sfdisk_options="--force --label gpt"
			else
				sfdisk_options="--force"
			fi
			sfdisk_boot_startmb="${sfdisk_boot_startmb}M"
		fi

		message="sfdisk: [$(LC_ALL=C sfdisk --version)]" ; broadcast
		message="sfdisk: [sfdisk ${sfdisk_options} ${destination}]" ; broadcast
		message="sfdisk: [${sfdisk_boot_startmb},${sfdisk_boot_endmb},${sfdisk_fstype},*]" ; broadcast

		LC_ALL=C sfdisk ${sfdisk_options} "${destination}" <<-__EOF__
			${sfdisk_boot_startmb},,${sfdisk_fstype},*
		__EOF__

		flush_cache
		format_single_root
		message="Formatting: ${destination} complete" ; broadcast
		message="-----------------------------" ; broadcast

		media_rootfs="1"
	fi
}
flash_emmc () {
	message="eMMC: prepareing ${destination}" ; broadcast
	flush_cache
	dd if=/dev/zero of=${destination} bs=1M count=108
	sync
	dd if=${destination} of=/dev/null bs=1M count=108
	sync
	flush_cache

	LC_ALL=C sfdisk --force --no-reread --in-order --Linux --unit M ${destination} <<-__EOF__
	1,,L,*
	__EOF__

	sync
	flush_cache
    partition_drive
    message="-----------------------------" ; broadcast
	message="Copying: ${conf_image} -> ${destination}p${media_rootfs}" ; broadcast
    message="mkdir /tmp/dest_rootfs" ; broadcast
    if [ ! -d /tmp/dest_rootfs ] ; then
       mkdir /tmp/dest_rootfs || true
    fi
	mount ${destination}p${media_rootfs} /tmp/dest_rootfs/ -o async,noatime

    message="-----------------------------" ; broadcast 
    message="mount -v -o offset=1048576 -t ext4 /opt/emmc/${conf_image} /tmp/source_rootfs" ; broadcast    
    if [ ! -d /tmp/source_rootfs ] ; then
        mkdir /tmp/source_rootfs || true
    fi 
    modprobe loop
    lsmod
    mount -v -o async,noatime,offset=1048576 -t ext4 /opt/emmc/${conf_image} /tmp/source_rootfs

	message="rsync: /tmp/source_rootfs -> /tmp/dest_rootfs/" ; broadcast
	rsync -aAx /tmp/source_rootfs/* /tmp/dest_rootfs/ --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found,/lib/modules/*,/uEnv.txt} || write_failure

	if [ -d /tmp/dest_rootfs/etc/ssh/ ] ; then
		#ssh keys will now get regenerated on the next bootup
		touch /tmp/dest_rootfs/etc/ssh/ssh.regenerate
		flush_cache
	fi	
    
    mkdir -p /tmp/dest_rootfs/lib/modules/$(uname -r)/ || true
	message="Copying: Kernel modules" ; broadcast
	message="rsync: /tmp/source_rootfs/lib/modules/$(uname -r)/ -> /tmp/dest_rootfs/lib/modules/$(uname -r)/" ; broadcast
	rsync -aAx /tmp/source_rootfs/lib/modules/$(uname -r)/* /tmp/dest_rootfs/lib/modules/$(uname -r)/ || write_failure
	flush_cache
    
	message="Final System Tweaks:" ; broadcast
	unset root_uuid
	root_uuid=$(/sbin/blkid -c /dev/null -s UUID -o value ${destination}p${media_rootfs})
	if [ "${root_uuid}" ] ; then
		sed -i -e 's:uuid=:#uuid=:g' /tmp/dest_rootfs/boot/uEnv.txt
		echo "uuid=${root_uuid}" >> /tmp/dest_rootfs/boot/uEnv.txt

		message="UUID=${root_uuid}" ; broadcast
		root_uuid="UUID=${root_uuid}"
	else
		#really a failure...
		root_uuid="${source}p${media_rootfs}"
	fi  

	message="Generating: /etc/fstab" ; broadcast
	echo "# /etc/fstab: static file system information." > /tmp/dest_rootfs/etc/fstab
	echo "#" >> /tmp/dest_rootfs/etc/fstab
	echo "${root_uuid}  /  ext4  noatime,errors=remount-ro  0  1" >> /tmp/dest_rootfs/etc/fstab
	echo "debugfs  /sys/kernel/debug  debugfs  defaults  0  0" >> /tmp/dest_rootfs/etc/fstab
	cat /tmp/dest_rootfs/etc/fstab

	message="/boot/uEnv.txt: disabling eMMC flasher script" ; broadcast
	script="cmdline=init=/opt/scripts/tools/eMMC/init-eMMC-flasher-v3-bbgw.sh"
	sed -i -e 's:'$script':#'$script':g' /tmp/dest_rootfs/boot/uEnv.txt
	cat /tmp/dest_rootfs/boot/uEnv.txt
	message="-----------------------------" ; broadcast   

	flush_cache
	message="running: chroot /tmp/dest_rootfs/ /usr/bin/bb-wl18xx-wlan0" ; broadcast

	mount --bind /proc /tmp/dest_rootfs/proc
	mount --bind /sys /tmp/dest_rootfs/sys
	mount --bind /dev /tmp/dest_rootfs/dev
	mount --bind /dev/pts /tmp/dest_rootfs/dev/pts

	modprobe wl18xx
	message="-----------------------------" ; broadcast
	message="lsmod" ; broadcast
	message="`lsmod`" ; broadcast
	message="-----------------------------" ; broadcast
	chroot /tmp/dest_rootfs/ /usr/bin/bb-wl18xx-wlan0
	message="-----------------------------" ; broadcast

	flush_cache
	message="initrd: `ls -lh /tmp/dest_rootfs/boot/initrd.img*`" ; broadcast

	umount -fl /tmp/dest_rootfs/dev/pts
	umount -fl /tmp/dest_rootfs/dev
	umount -fl /tmp/dest_rootfs/proc
	umount -fl /tmp/dest_rootfs/sys
	sleep 2

	flush_cache
	message="-----------------------------" ; broadcast
	umount /tmp/dest_rootfs/ || umount -l /tmp/dest_rootfs/ || write_failure  
    flush_cache    
    umount /tmp/source_rootfs/ || umount -l /tmp/source_rootfs/ || write_failure  
    flush_cache    
	message="Copying: ${conf_image} -> ${destination}p${media_rootfs} complete" ; broadcast
	message="-----------------------------" ; broadcast    
    if [ "x${is_bbb}" = "xenable" ] ; then
		[ -e /proc/$CYLON_PID ]  && kill $CYLON_PID
	fi
    
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

etc_mtab_symlink () {
	message="-----------------------------" ; broadcast
	message="Setting up: ln -s /proc/mounts /etc/mtab" ; broadcast
	mount -o rw,remount / || write_failure
	if [ -f /etc/mtab ] ; then
		rm -f /etc/mtab || write_failure
	fi
	ln -s /proc/mounts /etc/mtab || write_failure
	mount -o ro,remount / || write_failure
	message="-----------------------------" ; broadcast
}

auto_fsck () {
	etc_mtab_symlink
	message="-----------------------------" ; broadcast
	if [ "x${conf_partition1_fstype}" = "x0x83" ] ; then
		message="e2fsck -fy ${destination}p1" ; broadcast
		e2fsck -fy ${destination}p1 || write_failure
		message="-----------------------------" ; broadcast
	fi
	if [ "x${conf_partition2_fstype}" = "x0x83" ] ; then
		message="e2fsck -fy ${destination}p2" ; broadcast
		e2fsck -fy ${destination}p2 || write_failure
		message="-----------------------------" ; broadcast
	fi
	if [ "x${conf_partition3_fstype}" = "x0x83" ] ; then
		message="e2fsck -fy ${destination}p3" ; broadcast
		e2fsck -fy ${destination}p3 || write_failure
		message="-----------------------------" ; broadcast
	fi
	if [ "x${conf_partition4_fstype}" = "x0x83" ] ; then
		message="e2fsck -fy ${destination}p4" ; broadcast
		e2fsck -fy ${destination}p4 || write_failure
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
	message="resize2fs -f ${destination}p4" ; broadcast
	resize2fs -f ${destination}p4 || write_failure
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
	message="resize2fs -f ${destination}p3" ; broadcast
	resize2fs -f ${destination}p3 || write_failure
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
	message="resize2fs -f ${destination}p2" ; broadcast
	resize2fs -f ${destination}p2 || write_failure
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
	message="resize2fs -f ${destination}p1" ; broadcast
	resize2fs -f ${destination}p1 || write_failure
	message="-----------------------------" ; broadcast
}

resize_emmc () {
	unset resized

	conf_partition1_startmb=$(cat ${wfile} | grep -v '#' | grep conf_partition1_startmb | awk -F '=' '{print $2}' || true)
	conf_partition1_fstype=$(cat ${wfile} | grep -v '#' | grep conf_partition1_fstype | awk -F '=' '{print $2}' || true)
	conf_partition1_endmb=$(cat ${wfile} | grep -v '#' | grep conf_partition1_endmb | awk -F '=' '{print $2}' || true)

	conf_partition2_fstype=$(cat ${wfile} | grep -v '#' | grep conf_partition2_fstype | awk -F '=' '{print $2}' || true)
	conf_partition2_endmb=$(cat ${wfile} | grep -v '#' | grep conf_partition2_endmb | awk -F '=' '{print $2}' || true)

	conf_partition3_fstype=$(cat ${wfile} | grep -v '#' | grep conf_partition3_fstype | awk -F '=' '{print $2}' || true)
	conf_partition3_endmb=$(cat ${wfile} | grep -v '#' | grep conf_partition3_endmb | awk -F '=' '{print $2}' || true)

	conf_partition4_fstype=$(cat ${wfile} | grep -v '#' | grep conf_partition4_fstype | awk -F '=' '{print $2}' || true)

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
		eeprom_location="/sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/at24-0/nvmem"
		got_eeprom="true"
	fi

	#pre-v8 of nvmem...
	if [ -f /sys/class/nvmem/at24-0/nvmem ] && [ "x${got_eeprom}" = "x" ] ; then
		eeprom="/sys/class/nvmem/at24-0/nvmem"
		eeprom_location="/sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/nvmem/at24-0/nvmem"
		got_eeprom="true"
	fi

	#eeprom 3.8.x & 4.4 with eeprom-nvmem patchset...
	if [ -f /sys/bus/i2c/devices/0-0050/eeprom ] && [ "x${got_eeprom}" = "x" ] ; then
		eeprom="/sys/bus/i2c/devices/0-0050/eeprom"

		if [ -f /sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/eeprom ] ; then
			eeprom_location="/sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/eeprom"
		else
			eeprom_location=$(ls /sys/devices/ocp*/44e0b000.i2c/i2c-0/0-0050/eeprom 2> /dev/null)
		fi

		got_eeprom="true"
	fi

	if [ "x${is_bbb}" = "xenable" ] ; then
		if [ "x${got_eeprom}" = "xtrue" ] ; then
			eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -n 8 | cut -b 6-8)
			if [ "x${eeprom_header}" = "x${conf_eeprom_compare}" ] ; then
				message="Valid EEPROM header found [${eeprom_header}]" ; broadcast
				message="-----------------------------" ; broadcast
			else
				message="Invalid EEPROM header detected" ; broadcast
				if [ -f ${wdir}/${conf_eeprom_file} ] ; then
					if [ ! "x${eeprom_location}" = "x" ] ; then
						message="Writing header to EEPROM" ; broadcast
						dd if=${wdir}/${conf_eeprom_file} of=${eeprom_location} || write_failure
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
				else
					message="error: no [${wdir}/${conf_eeprom_file}]" ; broadcast
				fi
			fi
		fi
	fi
}

cylon_leds () {
	if [ "x${is_bbb}" = "xenable" ] ; then
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
	fi
}


process_job_file () {
	job_file=found
	if [ ! -f /usr/bin/dos2unix ] ; then
		message="Warning: dos2unix not installed, dont use windows to create job.txt file." ; broadcast
		sleep 1
	else
		dos2unix -n ${wfile} /tmp/job.txt
		wfile="/tmp/job.txt"
	fi
	message="Processing job.txt:" ; broadcast
	message="`cat ${wfile} | grep -v '#'`" ; broadcast
	message="-----------------------------" ; broadcast

	abi=$(cat ${wfile} | grep -v '#' | grep abi | awk -F '=' '{print $2}' || true)
	if [ "x${abi}" = "xaaa" ] ; then
		conf_eeprom_file=$(cat ${wfile} | grep -v '#' | grep conf_eeprom_file | awk -F '=' '{print $2}' || true)
		conf_eeprom_compare=$(cat ${wfile} | grep -v '#' | grep conf_eeprom_compare | awk -F '=' '{print $2}' || true)
		if [ ! "x${conf_eeprom_file}" = "x" ] ; then
			if [ -f ${wdir}/${conf_eeprom_file} ] ; then
				check_eeprom
			fi
		fi

		conf_image=$(cat ${wfile} | grep -v '#' | grep conf_image | awk -F '=' '{print $2}' || true)
		if [ ! "x${conf_image}" = "x" ] ; then
			if [ -f ${wdir}/${conf_image} ] ; then
				conf_bmap=$(cat ${wfile} | grep -v '#' | grep conf_bmap | awk -F '=' '{print $2}' || true)
				if [ "x${is_bbb}" = "xenable" ] ; then
					cylon_leds & CYLON_PID=$!
				fi
				flash_emmc
				conf_resize=$(cat ${wfile} | grep -v '#' | grep conf_resize | awk -F '=' '{print $2}' || true)
				if [ "x${conf_resize}" = "xenable" ] ; then
					message="resizing eMMC" ; broadcast
					message="-----------------------------" ; broadcast
					resize_emmc
				fi
				conf_root_partition=$(cat ${wfile} | grep -v '#' | grep conf_root_partition | awk -F '=' '{print $2}' || true)
				if [ ! "x${conf_root_partition}" = "x" ] ; then
					set_uuid
				fi

				if [ "x${is_bbb}" = "xenable" ] ; then
					[ -e /proc/$CYLON_PID ]  && kill $CYLON_PID
				fi
			else
				message="error: image not found [${wdir}/${conf_image}]" ; broadcast
			fi
		else
			message="error: image not defined [conf_image=${conf_image}]" ; broadcast
		fi
	else
		message="error: unable to decode: [job.txt]" ; broadcast
		sleep 10
		write_failure
	fi
}

check_usb_media () {
	wfile="/tmp/usb/job.txt"
	wdir="/tmp/usb"
	message="Checking external usb media" ; broadcast
	message="lsblk:" ; broadcast
	message="`lsblk || true`" ; broadcast
	message="-----------------------------" ; broadcast

	if [ "x${is_bbb}" = "xenable" ] ; then
		if [ ! -e /sys/class/leds/beaglebone\:green\:usr0/trigger ] ; then
			modprobe leds_gpio || true
			sleep 1
		fi
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

			if [ ! -f ${wfile} ] ; then
				umount "/tmp/usb/" || true
			else
				process_job_file
			fi

		fi
	i=$(($i+1))
	done

	if [ ! "x${job_file}" = "xfound" ] ; then
		if [ -f /opt/emmc/job.txt ] ; then
			wfile="/opt/emmc/job.txt"
			wdir="/opt/emmc"
			process_job_file
		else
			message="job.txt: format" ; broadcast
			message="-----------------------------" ; broadcast
			message="abi=aaa" ; broadcast
			message="conf_eeprom_file=<file>" ; broadcast
			message="conf_eeprom_compare=<6-8>" ; broadcast
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
	fi

	message="eMMC has been flashed: please wait for device to power down." ; broadcast
	message="-----------------------------" ; broadcast

	umount /tmp || umount -l /tmp

	if [ "x${is_bbb}" = "xenable" ] ; then
		if [ -e /sys/class/leds/beaglebone\:green\:usr0/trigger ] ; then
			echo default-on > /sys/class/leds/beaglebone\:green\:usr0/trigger
			echo default-on > /sys/class/leds/beaglebone\:green\:usr1/trigger
			echo default-on > /sys/class/leds/beaglebone\:green\:usr2/trigger
			echo default-on > /sys/class/leds/beaglebone\:green\:usr3/trigger
		fi
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
message="Version: [${version_message}]" ; broadcast
message="-----------------------------" ; broadcast

get_device
print_eeprom
check_usb_media
#
