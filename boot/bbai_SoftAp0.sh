#!/bin/bash
#
# Copyright (c) 2016-2018 Robert Nelson <robertcnelson@gmail.com>
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

#set -x
#set -e

until [ -d /sys/class/net/wlan0/ ] ; do
	sleep 3
	echo "SoftAp0: waiting for /sys/class/net/wlan0/"
done

/sbin/iw phy phy0 interface add SoftAp0 type managed
/sbin/ip link set dev SoftAp0 up
/sbin/ip addr flush dev SoftAp0
/sbin/ip addr add 192.168.8.1/24 broadcast 192.168.8.255 dev SoftAp0
echo 1 > /proc/sys/net/ipv4/ip_forward
/sbin/iptables -w -t nat -A POSTROUTING -o wlan0 -j MASQUERADE || true
/sbin/iptables -w -A FORWARD -i wlan0 -o SoftAp0 -m state --state RELATED,ESTABLISHED -j ACCEPT || true
/sbin/iptables -w -A FORWARD -i SoftAp0 -o wlan0 -j ACCEPT || true
/bin/systemctl restart hostapd

