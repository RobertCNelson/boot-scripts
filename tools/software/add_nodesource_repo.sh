#!/bin/bash

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

deb_distro=$(lsb_release -cs | sed 's/\//_/g')

check_dpkg () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}$" >/dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}

check_dpkg_installed () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}$" >/dev/null && deb_pkgs="${deb_pkgs}${pkg} "
}

apt-get update

unset deb_pkgs
pkg="apt-transport-https" ; check_dpkg
if [ ! "x${deb_pkgs}" = "x" ] ; then
	apt-get install -y ${deb_pkgs}
fi

apt-get -y upgrade

unset deb_pkgs
pkg="nodejs-dev" ; check_dpkg_installed
pkg="nodejs-v0.12.x" ; check_dpkg_installed
pkg="nodejs-v0.12.x-legacy" ; check_dpkg_installed

if [ ! "x${deb_pkgs}" = "x" ] ; then
	echo "removing conflicting packages"
	apt-get remove -y ${deb_pkgs} --purge
fi

wget -qO- https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -

check_sources=$(cat /etc/apt/sources.list | grep -v "#" | grep deb.nodesource.com || true)
if [ "x${check_sources}" = "x" ] ; then
	echo "adding nodesource repo"
	echo "" >> /etc/apt/sources.list
	echo "deb https://deb.nodesource.com/node_0.12 ${deb_distro} main" >> /etc/apt/sources.list
	echo "#deb-src https://deb.nodesource.com/node_0.12 ${deb_distro} main" >> /etc/apt/sources.list
fi

apt-get update
apt-get install -y nodejs

echo "node: [`/usr/bin/node --version`]"
echo "npm: [`/usr/bin/node /usr/bin/npm --version`]"
#
