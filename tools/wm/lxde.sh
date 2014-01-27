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

pkg="lxde-core"
check_dpkg
pkg="lightdm"
check_dpkg

if [ "${deb_pkgs}" ] ; then
	echo ""
	echo "Installing: ${deb_pkgs}"
	sudo apt-get update
	sudo apt-get -y install ${deb_pkgs}
	sudo apt-get clean
	echo "--------------------"
fi

if [ "x${USER}" != "xroot" ] ; then
	if [ -f /etc/lightdm/lightdm.conf ] ; then
		sudo sed -i -e 's:#autologin-user=:autologin-user='${USER}':g' /etc/lightdm/lightdm.conf
		sudo sed -i -e 's:#autologin-session=UNIMPLEMENTED:autologin-session=LXDE:g' /etc/lightdm/lightdm.conf
	fi
fi
#Disable LXDE's screensaver on autostart
if [ -f /etc/xdg/lxsession/LXDE/autostart ] ; then
	cat /etc/xdg/lxsession/LXDE/autostart | grep -v xscreensaver > /tmp/autostart
	sudo mv -v /tmp/autostart /etc/xdg/lxsession/LXDE/autostart
	rm -rf /tmp/autostart || true
fi
#
