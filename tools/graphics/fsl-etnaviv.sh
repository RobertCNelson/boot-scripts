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

pkg="libdrm-etnaviv0:${deb_arch}"
check_dpkg
#utils:
pkg="read-edid"
check_dpkg
pkg="x11-xserver-utils"
check_dpkg
#devel
pkg="libdrm-dev:${deb_arch}"
check_dpkg
pkg="git-core"
check_dpkg
pkg="build-essential"
check_dpkg
pkg="autoconf"
check_dpkg
pkg="libtool"
check_dpkg
pkg="pkg-config"
check_dpkg
pkg="xutils-dev"
check_dpkg
pkg="xserver-xorg-dev"
check_dpkg
pkg="libudev-dev:${deb_arch}"
check_dpkg

if [ "${deb_pkgs}" ] ; then
	echo ""
	echo "Installing: ${deb_pkgs}"
	sudo apt-get update
	sudo apt-get -y install ${deb_pkgs}
	sudo apt-get clean
	echo "--------------------"
fi

#git_sha="origin/master"
git_sha="origin/unstable-devel"
project="xf86-video-armada"
server="git://ftp.arm.linux.org.uk/~rmk"

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	git clone ${server}/${project}.git ${HOME}/git/${project}/
fi

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	rm -rf ${HOME}/git/${project}/ || true
	echo "error: git failure, try re-runing"
	exit
fi

cd ${HOME}/git/${project}/
make clean || true
git checkout master -f
git pull || true

test_for_branch=$(git branch --list ${git_sha}-build)
if [ "x${test_for_branch}" != "x" ] ; then
	git branch ${git_sha}-build -D
fi

git checkout ${git_sha} -b ${git_sha}-build
./autogen.sh --prefix=/usr --disable-etnaviv
make
sudo make install

exit

if [ ! -d /etc/X11/ ] ; then
	sudo mkdir -p /etc/X11/ || true
fi

if [ -f /etc/X11/xorg.conf ] ; then
	sudo rm -rf /etc/X11/xorg.conf.bak || true
	sudo mv /etc/X11/xorg.conf /etc/X11/xorg.conf.bak
fi

cat > /tmp/xorg.conf <<-__EOF__
	Section "Monitor"
	        Identifier      "Builtin Default Monitor"
	EndSection

	Section "Device"
	        Identifier      "Builtin Default fbdev Device 0"
	        Driver          "modesetting"
	        Option          "SWCursor"      "true"
	EndSection

	Section "Screen"
	        Identifier      "Builtin Default fbdev Screen 0"
	        Device          "Builtin Default fbdev Device 0"
	        Monitor         "Builtin Default Monitor"
	        DefaultDepth    24
	EndSection

	Section "ServerLayout"
	        Identifier      "Builtin Default Layout"
	        Screen          "Builtin Default fbdev Screen 0"
	EndSection
__EOF__

sudo cp -v /tmp/xorg.conf /etc/X11/xorg.conf
#
