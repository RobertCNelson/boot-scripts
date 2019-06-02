#!/bin/bash
#
# Copyright (c) 2017 David Lechner <david@lechnology.com>
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
#


#
# Auto-configuring the usb1 network interface:
#
# usb1 is the CDC/ECM gadget connection. It is managed by ConnMan and uses
# tethering so that it serves a DHCP address to attached hosts. The IPv4 subnet
# used by ConnMan is not consistent, so hosts should connect using the mDNS
# name (beaglebone.local) instead of an IP address.
#

# This is probably not needed if autoconfigure_usb0.sh is run first because it
# also waits for /sys/class/net/usb0/
until [ -d /sys/class/net/usb1/ ] ; do
	sleep 1
	echo "g_multi: waiting for /sys/class/net/usb1/"
done

# gadget is not supported by ConnMan provisioning files, so we have to do this
# the ugly way. Advanced users can comment these line to gain full control of
# the usb1 network interface.
#connmanctl enable gadget >/dev/null 2>&1
#connmanctl tether gadget on >/dev/null 2>&1

# if there is any pre-existing config for usb1, use that;
# otherwise use a static default
grep -rqE '^\s*iface usb1 inet' /etc/network/interfaces* && /sbin/ifup usb1 \
	|| /sbin/ifconfig usb1 192.168.6.2 netmask 255.255.255.252 \
	|| true
