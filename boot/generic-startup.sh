#!/bin/sh -e

#Regenerate ssh host keys
if [ -f /etc/ssh/ssh.regenerate ] ; then
	systemctl stop sshd
	rm -rf /etc/ssh/ssh_host_* || true
	dpkg-reconfigure openssh-server
	sync
	if [ -s /etc/ssh/ssh_host_ed25519_key.pub ] ; then
		rm -f /etc/ssh/ssh.regenerate || true
		sync
		systemctl start sshd
	fi
fi
