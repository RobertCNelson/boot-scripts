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
	USB1_SUBNET=192.168.6
	DNS_NAMESERVER=8.8.8.8
fi

ip addr flush dev usb1 || true
/sbin/dhclient usb1 || true
/sbin/route add default gw ${USB1_SUBNET}.1 || true

ping -c1 ${DNS_NAMESERVER}
echo "nameserver ${DNS_NAMESERVER}" >> /etc/resolv.conf

#
