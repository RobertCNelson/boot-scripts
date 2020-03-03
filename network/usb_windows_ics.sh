#!/bin/sh -e
#

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

if [ -f /etc/default/bb-boot ] ; then
	. /etc/default/bb-boot
fi

if [ "x${USB_CONFIGURATION}" = "x" ] ; then
	USB0_SUBNET=192.168.7
	DNS_NAMESERVER=8.8.8.8
fi

ip addr flush dev usb0 || true
/sbin/dhclient usb0 || true

#/sbin/route add default gw ${USB0_SUBNET}.1 || true

#ping -c1 ${DNS_NAMESERVER}
#echo "nameserver ${DNS_NAMESERVER}" >> /etc/resolv.conf

#
