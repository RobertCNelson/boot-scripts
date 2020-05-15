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

if [ ! "x${var_uname_r}" = "x" ] ; then
	if [ ! "x${var_cmdline}" = "x" ] ; then
		echo "label Linux ${var_uname_r}"
		echo "    kernel /boot/vmlinuz-${var_uname_r}"
		echo "    append ${var_cmdline}"
		echo "    fdtdir /boot/dtbs/${var_uname_r}/"
	fi
fi

