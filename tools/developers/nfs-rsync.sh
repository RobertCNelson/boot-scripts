#!/bin/bash -e

echo "sudo mkdir /tmp/rootfs/"
echo "sudo mount -t nfs -o rw,nfsvers=3,rsize=8192,wsize=8192 192.168.0.10:/opt/wheezy/ /tmp/rootfs/"

if [ -d /tmp/rootfs/ ] ; then
	sudo rsync -aAXv --delete /* /tmp/rootfs/ --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found}
fi
