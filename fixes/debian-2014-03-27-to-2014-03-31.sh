#!/bin/sh

if [ -f /etc/systemd/system/getty.target.wants/serial-getty@ttyGS0.service ] ; then
	echo "Already ran"
	exit
fi

check_dpkg () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}$" >/dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}

unset deb_pkgs

if [ "${deb_pkgs}" ] ; then
	echo "Installing: [${deb_pkgs}]"
	sudo apt-get update
	sudo apt-get -y install ${deb_pkgs}
fi

#https://github.com/beagleboard/image-builder/commit/15f944399c2ec3b88c9269411480bc0887468928
if [ -f /etc/systemd/system/getty.target.wants/getty@ttyGS0.service ] ; then
	sudo rm /etc/systemd/system/getty.target.wants/getty@ttyGS0.service

	sudo cp /lib/systemd/system/serial-getty@.service /etc/systemd/system/serial-getty@ttyGS0.service
	sudo ln -s /etc/systemd/system/serial-getty@ttyGS0.service /etc/systemd/system/getty.target.wants/serial-getty@ttyGS0.service
fi


#https://github.com/beagleboard/image-builder/commit/93952245774e6986c2a54b4993533e2e37601c8a
if [ -f /etc/sudoers ] ; then
	sudo sh -c "echo 'debian  ALL=NOPASSWD: ALL' >> /etc/sudoers"
fi

if [ -f /boot/uboot/uEnv.txt ] ; then
	sudo sed -i -e 's:bootargs console=:bootargs console=tty0 console=:g' /boot/uboot/uEnv.txt
fi

echo "Please Reboot"
