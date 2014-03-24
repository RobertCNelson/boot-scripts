#!/bin/sh

check_dpkg () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}$" >/dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}


unset deb_pkgs
pkg="wicd-cli"
check_dpkg
pkg="wicd-curses"
check_dpkg
#fixed: https://github.com/beagleboard/image-builder/commit/6af879606f2638dda363c54264e8e72ddb032b98

if [ "${deb_pkgs}" ] ; then
	echo "Installing: [${deb_pkgs}]"
	sudo apt-get update
	sudo apt-get -y install ${deb_pkgs}
fi

if [ -f /lib/systemd/system/getty@.service ] ; then
	ln -s /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@ttyGS0.service

	echo "" >> /etc/securetty
	echo "#USB Gadget Serial Port" >> /etc/securetty
	echo "ttyGS0" >> /etc/securetty
fi

echo "Please Reboot"
