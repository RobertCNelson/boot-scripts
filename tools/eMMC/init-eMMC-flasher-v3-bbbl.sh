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

#mke2fs -c
#Check the device for bad blocks before creating the file system.
#If this option is specified twice, then a slower read-write test is
#used instead of a fast read-only test.

mkfs_options=""
#mkfs_options="-c"
#mkfs_options="-cc"

device_eeprom="bbbl-eeprom"

check_if_run_as_root

startup_message
prepare_environment

countdown 5
check_eeprom
check_running_system
activate_cylon_leds

#We override the copy_rootfs that comes from functions.sh as this one has wireless added to it
_copy_rootfs() {
  empty_line
  generate_line 80 '='
  echo_broadcast "Copying: Current rootfs to ${rootfs_partition}"
  generate_line 40
  echo_broadcast "==> rsync: / -> ${tmp_rootfs_dir}"
  generate_line 40
  get_rsync_options
  rsync -aAx $rsync_options /* ${tmp_rootfs_dir} --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found,/lib/modules/*,/uEnv.txt} || write_failure
  flush_cache
  generate_line 40
  echo_broadcast "==> Copying: Kernel modules"
  echo_broadcast "===> Creating directory for modules"
  mkdir -p ${tmp_rootfs_dir}/lib/modules/$(uname -r)/ || true
  echo_broadcast "===> rsync: /lib/modules/$(uname -r)/ -> ${tmp_rootfs_dir}/lib/modules/$(uname -r)/"
  generate_line 40
  rsync -aAx $rsync_options /lib/modules/$(uname -r)/* ${tmp_rootfs_dir}/lib/modules/$(uname -r)/ || write_failure
  flush_cache
  generate_line 40

  echo_broadcast "Copying: Current rootfs to ${rootfs_partition} complete"
  generate_line 80 '='
  empty_line
  generate_line 80 '='
  echo_broadcast "Final System Tweaks:"
  generate_line 40
  if [ -d ${tmp_rootfs_dir}/etc/ssh/ ] ; then
    echo_broadcast "==> Applying SSH Key Regeneration trick"
    #ssh keys will now get regenerated on the next bootup
    touch ${tmp_rootfs_dir}/etc/ssh/ssh.regenerate
    flush_cache
  fi

  _generate_uEnv ${tmp_rootfs_dir}/boot/uEnv.txt

  _generate_fstab

  #FIXME: What about when you boot from a fat partition /boot ?
  echo_broadcast "==> /boot/uEnv.txt: disabling eMMC flasher script"
  sed -i -e 's:'$emmcscript':#'$emmcscript':g' ${tmp_rootfs_dir}/boot/uEnv.txt
  generate_line 40 '*'
  cat ${tmp_rootfs_dir}/boot/uEnv.txt
  generate_line 40 '*'
  flush_cache
	echo_broadcast "==> running: chroot /tmp/rootfs/ /usr/bin/bb-wl18xx-wlan0"
  echo_broadcast "==> bind some mount points"
	mount --bind /proc /tmp/rootfs/proc
	mount --bind /sys /tmp/rootfs/sys
	mount --bind /dev /tmp/rootfs/dev
	mount --bind /dev/pts /tmp/rootfs/dev/pts
  echo_broadcast "==> Load module wl18xx"
	modprobe wl18xx
  generate_line 40
	echo_broadcast "====> lsmod"
	echo_broadcast "`lsmod`"
  echo_broadcast "==> Chroot"
  generate_line 40
	chroot /tmp/rootfs/ /usr/bin/bb-wl18xx-wlan0
  generate_line 40

	flush_cache
  echo_broadcast "==> initrd: $(ls -lh /tmp/rootfs/boot/initrd.img*)"
  echo_broadcast "==> Unmount previous bind"
	umount -fl /tmp/rootfs/dev/pts
	umount -fl /tmp/rootfs/dev
	umount -fl /tmp/rootfs/proc
	umount -fl /tmp/rootfs/sys
	sleep 2

	flush_cache
  generate_line 80
}

prepare_drive

