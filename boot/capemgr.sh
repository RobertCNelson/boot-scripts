#!/bin/sh -e

if test -f /etc/default/capemgr; then
	. /etc/default/capemgr
fi

#CAPE="cape-bone-proto"

cape_list=$(echo ${CAPE} | sed "s/ //g" | sed "s/,/ /g")
capemgr=$(ls /sys/devices/bone_capemgr.*/slots 2> /dev/null || true)

load_overlay () {
	echo ${overlay} > ${capemgr}
}

if [ ! "x${cape_list}" = "x" ] ; then
	if [ ! "x${capemgr}" = "x" ] ; then
		for overlay in ${cape_list} ; do load_overlay ; done
	fi
fi
