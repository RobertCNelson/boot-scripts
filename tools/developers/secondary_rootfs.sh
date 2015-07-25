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

broadcast () {
	if [ "x${message}" != "x" ] ; then
		echo "${message}"
#		echo "${message}" > /dev/tty0 || true
	fi
}

umount ${destination}1 || true

dd if=/dev/zero of=${destination} bs=1M count=10

sync ; sleep 2

sfdisk --in-order --Linux --unit M ${destination} <<-__EOF__
1,,0x83,*
__EOF__

sync ; sleep 2

mkfs.ext4 ${destination}1

sync ; sleep 2

mkdir -p /tmp/rootfs/
mount ${destination}1  /tmp/rootfs/

sync ; sleep 2

rsync -aAXv /* /tmp/rootfs/ --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found}

sync ; sleep 2

message="-----------------------------" ; broadcast

message="Final System Tweaks:" ; broadcast
unset root_uuid
root_uuid=$(/sbin/blkid -c /dev/null -s UUID -o value /dev/sdc1)
if [ "${root_uuid}" ] ; then
	sed -i -e 's:uuid=:#uuid=:g' /boot/uEnv.txt
	echo "uuid=${root_uuid}" >> /boot/uEnv.txt

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
