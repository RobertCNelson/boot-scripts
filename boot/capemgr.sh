#!/bin/sh -e

if test -f /etc/default/capemgr; then
	. /etc/default/capemgr
fi

#CAPE="cape-bone-proto"

cape_list=$(echo ${CAPE} | sed "s/ //g" | sed "s/,/ /g")

#v4.1.x-capemgr added platform directory
if [ -f /sys/devices/platform/bone_capemgr/slots ] ; then
	capemgr="/sys/devices/platform/bone_capemgr/slots"
else
	capemgr=$(ls /sys/devices/bone_capemgr.*/slots 2> /dev/null || true)
fi

load_overlay () {
	echo ${overlay} > ${capemgr}
}

if [ ! "x${cape_list}" = "x" ] ; then
	if [ ! "x${capemgr}" = "x" ] ; then
		for overlay in ${cape_list} ; do load_overlay ; done
	fi
fi
