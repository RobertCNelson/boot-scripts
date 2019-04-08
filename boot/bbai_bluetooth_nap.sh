#!/bin/bash
#
# Copyright (c) 2016-2018 Robert Nelson <robertcnelson@gmail.com>
# Copyright (c) 2019 Texas Instruments, Jason Kridner <jdk@ti.com>
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

until [ -d /sys/class/bluetooth/hci0/ ] ; do
	sleep 3
	echo "bluetooth: waiting for /sys/class/bluetooth/hci0/"
done

brctl addbr btbridge0
ip link set dev btbridge0 address 11:22:33:44:55:66 || true
ip link set dev btbridge0 up
ip addr flush dev btbridge0
ip addr add 192.168.21.1/24 broadcast 192.168.21.255 dev btbridge0
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -w -t nat -A POSTROUTING -o wlan0 -j MASQUERADE || true
iptables -w -A FORWARD -i wlan0 -o btbridge0 -m state --state RELATED,ESTABLISHED -j ACCEPT || true
iptables -w -A FORWARD -i btbridge0 -o wlan0 -j ACCEPT || true
bt-network -s nap btbridge0 &
