#!/bin/bash -e

dist=$(lsb_release -cs)

echo "sudo mkdir /tmp/rootfs/"
echo "sudo mount -t nfs -o rw,nfsvers=3,rsize=8192,wsize=8192 192.168.0.10:/opt/${dist}/ /tmp/rootfs/"

if [ -d /tmp/rootfs/ ] ; then
	sudo rsync -aAXv --delete /* /tmp/rootfs/ --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found}
	sudo sh -c "echo 'debugfs  /sys/kernel/debug  debugfs  defaults  0  0' > /tmp/rootfs/etc/fstab"

	echo "client_ip=`ip addr list eth0 | grep \"inet \" |cut -d' ' -f6|cut -d/ -f1`"
	echo "server_ip=192.168.0.10"
	echo "gw_ip=192.168.0.1"
	echo "root_dir=/opt/${dist}"
fi

#
