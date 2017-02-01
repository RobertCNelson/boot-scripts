#!/bin/bash -e

if [ "$(which lsb_release)" ] ; then
	dist=$(lsb_release -cs)
else
	if [ -f /etc/rcn-ee.conf ] ; then
		. /etc/rcn-ee.conf
	fi

	if [ ! "x${deb_codename}" = "x" ] ;then
		dist=${deb_codename}
	else
		dist="jessie"
	fi
fi

echo "sudo mkdir /tmp/rootfs/"
echo "sudo mount -t nfs -o rw,nfsvers=3,rsize=8192,wsize=8192 192.168.0.10:/opt/${dist}/ /tmp/rootfs/"

if [ -d /tmp/rootfs/ ] ; then
	sudo rsync -aAx --human-readable --info=name0,progress2 --delete /* /tmp/rootfs/ --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found}
	sudo sh -c "echo 'debugfs  /sys/kernel/debug  debugfs  defaults  0  0' > /tmp/rootfs/etc/fstab"

	if [ ! "x${dist}" = "xstretch" ] ;then
		if [ -f /tmp/rootfs/lib/systemd/system/connman.service ] ; then
			unset check_connman
			check_connman=$(cat /tmp/rootfs/lib/systemd/system/connman.service | grep ExecStart | grep eth0 || true)
			if [ "x${check_connman}" = "x" ] ; then
				sudo sed -i -e 's:-n:-n -I eth0:g' /tmp/rootfs/lib/systemd/system/connman.service
			fi
		fi
	fi

	echo "#uname_r=`uname -r`"
	echo "client_ip=`ip addr list eth0 | grep \"inet \" |cut -d' ' -f6|cut -d/ -f1`"
	echo "server_ip=192.168.0.10"
	echo "gw_ip=192.168.0.1"
	echo "root_dir=/opt/${dist}"
fi

#
