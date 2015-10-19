#!/bin/bash -e
#
# Copyright (c) 2015 Robert Nelson <robertcnelson@gmail.com>
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

destination="/dev/sda"
source="/dev/mmcblk0"

broadcast () {
	if [ "x${message}" != "x" ] ; then
		echo "${message}"
#		echo "${message}" > /dev/tty0 || true
	fi
}

##FIXME: quick check for rsync 3.1 (jessie)
unset rsync_check
unset rsync_progress
rsync_check=$(LC_ALL=C rsync --version | grep version | awk '{print $3}' || true)
if [ "x${rsync_check}" = "x3.1.1" ] ; then
	rsync_progress="--info=progress2 --human-readable"
fi

umount ${destination}1 || true

format_boot () {
	message="mkfs.vfat -F 16 ${destination}p1 -n ${boot_label}" ; broadcast
	echo "-----------------------------"
	mkfs.vfat -F 16 ${destination}p1 -n ${boot_label}
	echo "-----------------------------"
}

format_root () {
	message="mkfs.ext4 ${destination}p2 -L ${rootfs_label}" ; broadcast
	echo "-----------------------------"
	mkfs.ext4 ${destination}p2 -L ${rootfs_label}
	echo "-----------------------------"
}

format_single_root () {
	message="mkfs.ext4 ${destination}1 -L ${boot_label}" ; broadcast
	echo "-----------------------------"
	mkfs.ext4 ${destination}1 -L ${boot_label}
	echo "-----------------------------"
}

copy_rootfs () {
	message="Copying: ${source}p${media_rootfs} -> ${destination}${media_rootfs}" ; broadcast
	mkdir -p /tmp/rootfs/ || true

	mount ${destination}${media_rootfs} /tmp/rootfs/ -o async,noatime

	message="rsync: / -> /tmp/rootfs/" ; broadcast
	if [ ! "x${rsync_progress}" = "x" ] ; then
		echo "rsync: note the % column is useless..."
	fi
	rsync -aAx ${rsync_progress} /* /tmp/rootfs/ --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found,/lib/modules/*,/uEnv.txt}
	#flush_cache

	mkdir -p /tmp/rootfs/lib/modules/$(uname -r)/ || true

	message="Copying: Kernel modules" ; broadcast
	message="rsync: /lib/modules/$(uname -r)/ -> /tmp/rootfs/lib/modules/$(uname -r)/" ; broadcast
	if [ ! "x${rsync_progress}" = "x" ] ; then
		echo "rsync: note the % column is useless..."
	fi
	rsync -aAx ${rsync_progress} /lib/modules/$(uname -r)/* /tmp/rootfs/lib/modules/$(uname -r)/
	#flush_cache

	message="Copying: ${source}p${media_rootfs} -> ${destination}${media_rootfs} complete" ; broadcast
	message="-----------------------------" ; broadcast

	message="Final System Tweaks:" ; broadcast
	unset root_uuid
	root_uuid=$(/sbin/blkid -c /dev/null -s UUID -o value ${destination}${media_rootfs})

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

	message="UUID=${root_uuid}" ; broadcast
	root_uuid="UUID=${root_uuid}"

	message="Generating: /etc/fstab" ; broadcast
	echo "# /etc/fstab: static file system information." > /tmp/rootfs/etc/fstab
	echo "#" >> /tmp/rootfs/etc/fstab
	echo "${root_uuid}  /  ext4  noatime,errors=remount-ro  0  1" >> /tmp/rootfs/etc/fstab
	echo "debugfs  /sys/kernel/debug  debugfs  defaults  0  0" >> /tmp/rootfs/etc/fstab
	cat /tmp/rootfs/etc/fstab

	umount /tmp/rootfs/ || umount -l /tmp/rootfs/
}

partition_drive () {
	message="Erasing: ${destination}" ; broadcast
	dd if=/dev/zero of=${destination} bs=1M count=108
	sync
	dd if=${destination} of=/dev/null bs=1M count=108
	sync
	message="Erasing: ${destination} complete" ; broadcast
	message="-----------------------------" ; broadcast

	conf_boot_startmb=${conf_boot_startmb:-"1"}
	sfdisk_fstype=${sfdisk_fstype:-"0x83"}
	boot_label=${boot_label:-"rootfs"}

	message="Formatting: ${destination}" ; broadcast

	sfdisk_options="--force --Linux --in-order --unit M"
	sfdisk_boot_startmb="${conf_boot_startmb}"

	test_sfdisk=$(LC_ALL=C sfdisk --help | grep -m 1 -e "--in-order" || true)
	if [ "x${test_sfdisk}" = "x" ] ; then
		message="sfdisk: [2.26.x or greater]" ; broadcast
		sfdisk_options="--force"
		sfdisk_boot_startmb="${sfdisk_boot_startmb}M"
	fi

	message="sfdisk: [sfdisk ${sfdisk_options} ${destination}]" ; broadcast
	message="sfdisk: [${sfdisk_boot_startmb},${sfdisk_boot_endmb},${sfdisk_fstype},*]" ; broadcast

	LC_ALL=C sfdisk ${sfdisk_options} "${destination}" <<-__EOF__
		${sfdisk_boot_startmb},,${sfdisk_fstype},*
	__EOF__

}

if [ ! -f /boot/initrd.img-$(uname -r) ] ; then
	update-initramfs -c -k $(uname -r)
else
	update-initramfs -u -k $(uname -r)
fi

partition_drive
format_single_root
media_rootfs="1"
copy_rootfs
