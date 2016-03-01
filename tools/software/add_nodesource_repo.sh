#!/bin/bash

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

deb_distro=$(lsb_release -cs | sed 's/\//_/g')

check_dpkg () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}$" >/dev/null && deb_pkgs="${deb_pkgs}${pkg} "
}

check_sources=$(cat /etc/apt/sources.list | grep deb.nodesource.com || true)
if [ "x${check_sources}" = "x" ] ; then

	apt-get update

	unset deb_pkgs
	pkg="npm" ; check_dpkg
	pkg="nodejs-v0.12.x" ; check_dpkg
	pkg="nodejs-v0.12.x-legacy" ; check_dpkg

	echo "removing conflicting packages"
	apt-get remove ${deb_pkgs} --purge

	echo "adding nodesource repo"
	echo "deb https://deb.nodesource.com/node_0.12 ${deb_distro} main" >> /etc/apt/sources.list
	echo "#deb-src https://deb.nodesource.com/node_0.12 ${deb_distro} main" >> /etc/apt/sources.list

	wget -qO- https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -

	apt-get update
	apt-get install nodejs
fi
