#!/bin/sh -e
#
# Copyright (c) 2014 Robert Nelson <robertcnelson@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

check_dpkg () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}$" >/dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}

deb_distro=$(lsb_release -cs)
deb_arch=$(LC_ALL=C dpkg --print-architecture)

unset deb_pkgs
pkg="build-essential"
check_dpkg

pkg="autoconf"
check_dpkg

pkg="libtool"
check_dpkg

pkg="intltool"
check_dpkg

pkg="pkg-config"
check_dpkg

pkg="libwayland-dev"
check_dpkg

pkg="libgtk-3-dev"
check_dpkg

pkg="libgnome-menu-3-dev"
check_dpkg

pkg="libgnome-desktop-3-dev"
check_dpkg

pkg="libasound2-dev:${deb_arch}"
check_dpkg

pkg="libxml2-utils"
check_dpkg

if [ "${deb_pkgs}" ] ; then
	echo ""
	echo "Installing: ${deb_pkgs}"
	sudo apt-get update
	sudo apt-get -y install ${deb_pkgs}
	sudo apt-get clean
	echo "--------------------"
fi

git_generic () {
	if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
		git clone ${server} ${HOME}/git/${project}/ || true
	fi

	if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
		rm -rf ${HOME}/git/${project}/ || true
		echo "error: git failure, try re-runing"
		exit
	fi

	echo ""
	echo "Building ${project}"
	echo ""

	cd ${HOME}/git/${project}/

	make distclean >/dev/null 2>&1 || true
	git checkout master -f
	git pull || true

	if [ ! "x${git_sha}" = "x" ] ; then
		test_for_branch=$(git branch --list ${git_sha}-build)
		if [ "x${test_for_branch}" != "x" ] ; then
			git branch ${git_sha}-build -D
		fi

		git checkout ${git_sha} -b ${git_sha}-build
	fi
}

git_sha=""
project="maynard"
server="https://github.com/raspberrypi/maynard.git"

git_generic

./autogen.sh --prefix=/usr --libdir=/usr/lib/arm-linux-gnueabihf --libexecdir=/usr/lib/arm-linux-gnueabihf
make
sudo make install

#
