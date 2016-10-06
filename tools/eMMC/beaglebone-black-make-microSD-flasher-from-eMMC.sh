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

#
#https://rcn-ee.com/repos/bootloader/am335x_evm/
http_spl="MLO-am335x_evm-v2016.03-r7"
http_uboot="u-boot-am335x_evm-v2016.03-r7.img"

check_if_run_as_root

find_root_drive

boot_drive="${root_drive%?}1"

if [ "x${boot_drive}" = "x/dev/mmcblk0p1" ] ; then
	source="/dev/mmcblk0"
	destination="/dev/mmcblk1"
fi

if [ "x${boot_drive}" = "x/dev/mmcblk1p1" ] ; then
	source="/dev/mmcblk1"
	destination="/dev/mmcblk0"
fi

echo ""
echo "Unmounting Partitions"
echo "-----------------------------"

NUM_MOUNTS=$(mount | grep -v none | grep "${destination}" | wc -l)

i=0 ; while test $i -le ${NUM_MOUNTS} ; do
	DRIVE=$(mount | grep -v none | grep "${destination}" | tail -1 | awk '{print $1}')
	umount ${DRIVE} >/dev/null 2>&1 || true
	i=$(($i+1))
done

broadcast () {
	if [ "x${message}" != "x" ] ; then
		echo "${message}"
		#echo "${message}" > /dev/tty0 || true
	fi
}

check_running_system () {
	message="copying: [${source}] -> [${destination}]" ; broadcast
	message="lsblk:" ; broadcast
	message="`lsblk || true`" ; broadcast
	message="-----------------------------" ; broadcast
	message="df -h | grep rootfs:" ; broadcast
	message="`df -h | grep rootfs || true`" ; broadcast
	message="-----------------------------" ; broadcast

	if [ ! -b "${destination}" ] ; then
		message="Error: [${destination}] does not exist" ; broadcast
		write_failure
	fi

	if [ ! -f /boot/config-$(uname -r) ] ; then
		zcat /proc/config.gz > /boot/config-$(uname -r)
	fi

	if [ -f /boot/initrd.img-$(uname -r) ] ; then
		update-initramfs -u -k $(uname -r)
	else
		update-initramfs -c -k $(uname -r)
	fi
	flush_cache

	if [ "x${is_bbb}" = "xenable" ] ; then
		if [ ! -e /sys/class/leds/beaglebone\:green\:usr0/trigger ] ; then
			modprobe leds_gpio || true
			sleep 1
		fi
	fi
}

copy_boot () {
	message="Copying: ${source}p1 -> ${destination}p1" ; broadcast
	mkdir -p /tmp/boot/ || true

	umount ${source}p1 || umount -l ${source}p1 || true

	if ! mount -o sync ${source}p1 /boot/uboot/; then
		echo "-----------------------------"
		echo "BUG: [mount -o sync ${source}p1 /boot/uboot/] was not available so trying to mount again in 5 seconds..."
		sync
		sleep 5
		echo "-----------------------------"

		if ! mount -o sync ${source}p1 /boot/uboot/; then
			echo "mounting ${source}p1 failed.."
			exit
		fi
	fi

	if ! mount -o sync ${destination}p1 /tmp/boot/; then
		echo "-----------------------------"
		echo "BUG: [mount -o sync ${destination}p1 /tmp/boot/] was not available so trying to mount again in 5 seconds..."
		sync
		sleep 5
		echo "-----------------------------"

		if ! mount -o sync ${destination}p1 /tmp/boot/; then
			echo "mounting ${destination}p1 failed.."
			exit
		fi
	fi

	if [ -f /boot/uboot/MLO ] ; then
		#Make sure the BootLoader gets copied first:
		cp -v /boot/uboot/MLO /tmp/boot/MLO || write_failure
		flush_cache

		cp -v /boot/uboot/u-boot.img /tmp/boot/u-boot.img || write_failure
		flush_cache
	fi

	message="rsync: /boot/uboot/ -> /tmp/boot/" ; broadcast
	rsync -aAx /boot/uboot/ /tmp/boot/ --exclude={MLO,u-boot.img,uEnv.txt} || write_failure
	flush_cache

	flush_cache
	umount /tmp/boot/ || umount -l /tmp/boot/ || write_failure
	flush_cache
	umount /boot/uboot || umount -l /boot/uboot || true
}

copy_rootfs () {
	message="Copying: ${source}p${media_rootfs} -> ${destination}p${media_rootfs}" ; broadcast
	mkdir -p /tmp/rootfs/ || true

	if ! mount -o async,noatime ${destination}p${media_rootfs} /tmp/rootfs/; then
		echo "-----------------------------"
		echo "BUG: [mount -o sync ${destination}p${media_rootfs} /tmp/rootfs/] was not available so trying to mount again in 5 seconds..."
		sync
		sleep 5
		echo "-----------------------------"

		if ! mount -o async,noatime ${destination}p${media_rootfs} /tmp/rootfs/; then
			echo "mounting ${destination}p${media_rootfs} failed.."
			exit
		fi
	fi

	message="rsync: / -> /tmp/rootfs/" ; broadcast
	rsync -aAx /* /tmp/rootfs/ --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found,/lib/modules/*,/uEnv.txt} || write_failure
	flush_cache

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

	if [ ! -f /opt/scripts/tools/eMMC/init-eMMC-flasher-v3.sh ] ; then
		mkdir -p /opt/scripts/tools/eMMC/
		wget --directory-prefix="/opt/scripts/tools/eMMC/" https://raw.githubusercontent.com/RobertCNelson/boot-scripts/master/tools/eMMC/init-eMMC-flasher-v3.sh
		sudo chmod +x /opt/scripts/tools/eMMC/init-eMMC-flasher-v3.sh
	fi

	message="Generating: /etc/fstab" ; broadcast
	echo "# /etc/fstab: static file system information." > /tmp/rootfs/etc/fstab
	echo "#" >> /tmp/rootfs/etc/fstab
	echo "${root_uuid}  /  ext4  noatime,errors=remount-ro  0  1" >> /tmp/rootfs/etc/fstab
	echo "debugfs  /sys/kernel/debug  debugfs  defaults  0  0" >> /tmp/rootfs/etc/fstab
	cat /tmp/rootfs/etc/fstab

	message="/boot/uEnv.txt: enabling eMMC flasher script" ; broadcast
	script="cmdline=init=/opt/scripts/tools/eMMC/init-eMMC-flasher-v3.sh"
	echo "${script}" >> /tmp/rootfs/boot/uEnv.txt
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
	fi
}

partition_drive () {
	message="Erasing: ${destination}" ; broadcast
	flush_cache
	dd if=/dev/zero of=${destination} bs=1M count=108
	sync
	dd if=${destination} of=/dev/null bs=1M count=108
	sync
	flush_cache
	message="Erasing: ${destination} complete" ; broadcast
	message="-----------------------------" ; broadcast

	if [ -f /boot/SOC.sh ] ; then
		. /boot/SOC.sh
	fi

	#Debian Stretch; mfks.ext4 default to metadata_csum,64bit disable till u-boot works again..
	unset ext4_options
	unset test_mke2fs
	LC_ALL=C mkfs.ext4 -V &> /tmp/mkfs
	test_mkfs=$(cat /tmp/mkfs | grep mke2fs | grep 1.43 || true)
	if [ "x${test_mkfs}" = "x" ] ; then
		ext4_options="-c"
	else
		ext4_options="-c -O ^metadata_csum,^64bit"
	fi

	if [ "x${dd_spl_uboot_backup}" = "x" ] ; then
		spl_uboot_name="MLO"
		dd_spl_uboot_count="1"
		dd_spl_uboot_seek="1"
		dd_spl_uboot_conf=""
		dd_spl_uboot_bs="128k"
		dd_spl_uboot_backup="/opt/backup/uboot/MLO"

		echo "spl_uboot_name=${spl_uboot_name}" >> /boot/SOC.sh
		echo "dd_spl_uboot_count=1" >> /boot/SOC.sh
		echo "dd_spl_uboot_seek=1" >> /boot/SOC.sh
		echo "dd_spl_uboot_conf=" >> /boot/SOC.sh
		echo "dd_spl_uboot_bs=128k" >> /boot/SOC.sh
		echo "dd_spl_uboot_backup=${dd_spl_uboot_backup}" >> /boot/SOC.sh
	fi

	if [ ! -f /opt/backup/uboot/MLO ] ; then
		mkdir -p /opt/backup/uboot/
		wget --directory-prefix=/opt/backup/uboot/ http://rcn-ee.com/repos/bootloader/am335x_evm/${http_spl}
		mv /opt/backup/uboot/${http_spl} /opt/backup/uboot/MLO
	fi

	if [ "x${dd_uboot_backup}" = "x" ] ; then
		uboot_name="u-boot.img"
		dd_uboot_count="2"
		dd_uboot_seek="1"
		dd_uboot_conf=""
		dd_uboot_bs="384k"
		dd_uboot_backup="/opt/backup/uboot/u-boot.img"

		echo "uboot_name=${uboot_name}" >> /boot/SOC.sh
		echo "dd_uboot_count=2" >> /boot/SOC.sh
		echo "dd_uboot_seek=1" >> /boot/SOC.sh
		echo "dd_uboot_conf=" >> /boot/SOC.sh
		echo "dd_uboot_bs=384k" >> /boot/SOC.sh
		echo "dd_uboot_backup=${dd_uboot_backup}" >> /boot/SOC.sh

		echo "dd_uboot_name=${dd_uboot_name}" >> /boot/SOC.sh
	fi

	if [ ! -f /opt/backup/uboot/u-boot.img ] ; then
		mkdir -p /opt/backup/uboot/
		wget --directory-prefix=/opt/backup/uboot/ http://rcn-ee.com/repos/bootloader/am335x_evm/${http_uboot}
		mv /opt/backup/uboot/${http_uboot} /opt/backup/uboot/u-boot.img
	fi

	dd_bootloader

	if [ "x${boot_fstype}" = "xfat" ] ; then
		conf_boot_startmb=${conf_boot_startmb:-"4"}
		conf_boot_endmb=${conf_boot_endmb:-"96"}
		sfdisk_fstype=${sfdisk_fstype:-"0xE"}
		boot_label=${boot_label:-"BEAGLEBONE"}
		rootfs_label=${rootfs_label:-"rootfs"}

		message="Formatting: ${destination}" ; broadcast

		sfdisk_options="--force --Linux --in-order --unit M"
		sfdisk_boot_startmb="${conf_boot_startmb}"
		sfdisk_boot_size_mb="${conf_boot_endmb}"
		sfdisk_rootfs_startmb=$(($sfdisk_boot_startmb + $sfdisk_boot_size_mb))

		test_sfdisk=$(LC_ALL=C sfdisk --help | grep -m 1 -e "--in-order" || true)
		if [ "x${test_sfdisk}" = "x" ] ; then
			message="sfdisk: [2.26.x or greater]" ; broadcast
			sfdisk_options="--force"
			sfdisk_boot_startmb="${sfdisk_boot_startmb}M"
			sfdisk_boot_size_mb="${sfdisk_boot_size_mb}M"
			sfdisk_rootfs_startmb="${sfdisk_rootfs_startmb}M"
		fi

		message="sfdisk: [sfdisk ${sfdisk_options} ${destination}]" ; broadcast
		message="sfdisk: [${sfdisk_boot_startmb},${sfdisk_boot_size_mb},${sfdisk_fstype},*]" ; broadcast
		message="sfdisk: [${sfdisk_rootfs_startmb},,,-]" ; broadcast

		LC_ALL=C sfdisk ${sfdisk_options} "${destination}" <<-__EOF__
			${sfdisk_boot_startmb},${sfdisk_boot_size_mb},${sfdisk_fstype},*
			${sfdisk_rootfs_startmb},,,-
		__EOF__

		flush_cache
		format_boot
		format_root
		message="Formatting: ${destination} complete" ; broadcast
		message="-----------------------------" ; broadcast

		copy_boot
		media_rootfs="2"
		copy_rootfs
	else
		conf_boot_startmb=${conf_boot_startmb:-"4"}
		sfdisk_fstype=${sfdisk_fstype:-"L"}
		if [ "x${sfdisk_fstype}" = "x0x83" ] ; then
			sfdisk_fstype="L"
		fi
		boot_label=${boot_label:-"BEAGLEBONE"}
		if [ "x${boot_label}" = "xBOOT" ] ; then
			boot_label="rootfs"
		fi

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
		message="sfdisk: [${sfdisk_boot_startmb},,${sfdisk_fstype},*]" ; broadcast

		LC_ALL=C sfdisk ${sfdisk_options} "${destination}" <<-__EOF__
			${sfdisk_boot_startmb},,${sfdisk_fstype},*
		__EOF__

		flush_cache
		format_single_root
		message="Formatting: ${destination} complete" ; broadcast
		message="-----------------------------" ; broadcast

		media_rootfs="1"
		copy_rootfs
	fi
}

clear
message="-----------------------------" ; broadcast
message="Version: [${version_message}]" ; broadcast
message="-----------------------------" ; broadcast

get_device
check_running_system
activate_cylon_leds
partition_drive
#
