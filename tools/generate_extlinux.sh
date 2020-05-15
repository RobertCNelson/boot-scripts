#!/bin/sh -e
#

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

if [ ! -d /boot/extlinux/ ] ; then
	mkdir /boot/extlinux/ || true
fi

uname_r=$(cat /boot/uEnv.txt | grep -v '#' | sed 's/ /\n/g' | grep 'uname_r=' | awk -F"=" '{print $2}' || true)
cmdline=$(cat /boot/uEnv.txt | grep -v '#' | sed 's/ /\n/g' | grep 'cmdline=' | awk -F"=" '{print $2}' || true)

if [ ! "x${uname_r}" = "x" ] ; then
	if [ ! "x${cmdline}" = "x" ] ; then
		echo "label Linux ${uname_r}"
		echo "    kernel /boot/vmlinuz-${uname_r}"
		echo "    append ${cmdline}"
		echo "    fdtdir /boot/dtbs/${uname_r}/"
	fi
fi

