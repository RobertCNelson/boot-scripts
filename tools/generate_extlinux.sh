#!/bin/sh -e
#

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

if [ ! -d /boot/extlinux/ ] ; then
	mkdir /boot/extlinux/ || true
fi

var_uname_r=$(cat /boot/uEnv.txt | grep -v '#' | sed 's/ /\n/g' | grep 'uname_r=' | awk -F"=" '{print $2}' || true)
var_cmdline=$(cat /boot/uEnv.txt | grep -v '#' | grep 'cmdline=' || true)
var_cmdline=${var_cmdline##*cmdline=}

unset root_drive
root_drive="$(cat /proc/cmdline | sed 's/ /\n/g' | grep ^root=UUID= | awk -F 'root=' '{print $2}' || true)"
if [ ! "x${root_drive}" = "x" ] ; then
	root_drive="$(/sbin/findfs ${root_drive} || true)"
else
	root_drive="$(cat /proc/cmdline | sed 's/ /\n/g' | grep ^root= | awk -F 'root=' '{print $2}' || true)"
fi

var_file_system="console=ttyS0,115200n8 root=${root_drive} ro rootfstype=ext4 rootwait"

if [ ! "x${var_uname_r}" = "x" ] ; then
	echo "label Linux ${var_uname_r}" > /boot/extlinux/extlinux.conf
	echo "    kernel /boot/vmlinuz-${var_uname_r}" >> /boot/extlinux/extlinux.conf
	if [ ! "x${var_cmdline}" = "x" ] ; then
		echo "    append ${var_file_system} ${var_cmdline}" >> /boot/extlinux/extlinux.conf
	else
		echo "    append ${var_file_system}" >> /boot/extlinux/extlinux.conf
	fi
	echo "    fdtdir /boot/dtbs/${var_uname_r}/" >> /boot/extlinux/extlinux.conf
fi

if [ -f /boot/extlinux/extlinux.conf ] ; then
	echo "debug: /boot/extlinux/extlinux.conf"
	echo "-----------------------------------"
	cat /boot/extlinux/extlinux.conf
	echo "-----------------------------------"
fi

