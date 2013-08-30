#!/bin/sh -e

if [ -f /etc/ssh/ssh_host_dsa_key.pub ] ; then
	unset fix_ssh
	cat /etc/ssh/ssh_host_dsa_key.pub | grep "@`cat /etc/hostname`" || fix_ssh=1

	if [ "${fix_ssh}" ] ; then
		rm -rf /etc/ssh/ssh_host_* || true
		dpkg-reconfigure openssh-server
	fi
fi
