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

#autotools
pkg="autoconf"
check_dpkg
pkg="libtool"
check_dpkg
pkg="pkg-config"
check_dpkg

pkg="check:${deb_arch}"
check_dpkg

#Graphics libs
pkg="libgif-dev"
check_dpkg
pkg="libtiff5-dev:${deb_arch}"
check_dpkg

pkg="libbullet-dev:${deb_arch}"
check_dpkg

pkg="libglib2.0-dev"
check_dpkg

pkg="libgstreamer1.0-dev"
check_dpkg

#pkg="libmount-dev"
#check_dpkg

pkg="libpulse-dev:${deb_arch}"
check_dpkg

pkg="libsndfile1-dev"
check_dpkg

pkg="libssl-dev:${deb_arch}"
check_dpkg

pkg="libudev-dev"
check_dpkg

pkg="libxkbcommon-dev"
check_dpkg

pkg="libluajit-5.1-dev:${deb_arch}"
check_dpkg

pkg="libfribidi-dev"
check_dpkg

pkg="libfreetype6-dev"
check_dpkg

pkg="libfontconfig1-dev:${deb_arch}"
check_dpkg

#--enable-wayland
pkg="libwayland-dev"
check_dpkg

#--enable-systemd
pkg="libsystemd-daemon-dev"
check_dpkg
pkg="libsystemd-journal-dev"
check_dpkg

#--enable-pixman
pkg="libpixman-1-dev"
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
project="efl"
server="git://git.enlightenment.org/core/efl.git"

git_generic

#[bug]: efl assumes neon is: -mfloat-abi=softfp -mfpu=neon
#--disable-neon

#./autogen.sh --prefix=/usr --enable-systemd --enable-wayland --enable-fb --enable-pixman --with-x11=none --disable-tslib --disable-libmount --disable-gstreamer1 --disable-neon --enable-i-really-know-what-i-am-doing-and-that-this-will-probably-break-things-and-i-will-fix-them-myself-and-send-patches-aaa
#make -j5
#sudo make install

#someday:
#./autogen.sh --prefix=/usr --enable-systemd --enable-wayland --enable-egl --with-opengl=es

git_sha=""
project="elementary"
server="git://git.enlightenment.org/core/elementary.git"

git_generic

./autogen.sh --prefix=/usr
make
sudo make install

#
