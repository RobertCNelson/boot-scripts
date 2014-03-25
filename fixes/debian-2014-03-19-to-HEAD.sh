#!/bin/sh

check_dpkg () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}$" >/dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}


unset deb_pkgs
pkg="wicd-cli"
check_dpkg
pkg="wicd-curses"
check_dpkg
pkg="xrdp"
check_dpkg

if [ "${deb_pkgs}" ] ; then
	echo "Installing: [${deb_pkgs}]"
	sudo apt-get update
	sudo apt-get -y install ${deb_pkgs}
fi

if [ -f /lib/systemd/system/getty@.service ] ; then
	sudo ln -s /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@ttyGS0.service

	sudo sh -c "echo '' >> /etc/securetty"
	sudo sh -c "echo '#USB Gadget Serial Port' >> /etc/securetty"
	sudo sh -c "echo 'ttyGS0' >> /etc/securetty"
fi

echo "Please Reboot"
