#!/bin/sh -e
#

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

/sbin/route add default gw 192.168.7.1 || true

ping -c1 8.8.8.8
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

#
