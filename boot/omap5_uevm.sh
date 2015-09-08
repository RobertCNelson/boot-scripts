#!/bin/sh -e
#
# Copyright (c) 2013-2015 Robert Nelson <robertcnelson@gmail.com>
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

#Make sure the cpu_thermal zone is enabled...
if [ -f /sys/class/thermal/thermal_zone0/mode ] ; then
	echo enabled > /sys/class/thermal/thermal_zone0/mode
fi

eth0_addr=$(ip addr list eth0 |grep "inet " |cut -d' ' -f6|cut -d/ -f1)
usb0_addr=$(ip addr list usb0 |grep "inet " |cut -d' ' -f6|cut -d/ -f1)
#wlan0_addr=$(ip addr list wlan0 |grep "inet " |cut -d' ' -f6|cut -d/ -f1)

sed -i -e '/Address/d' /etc/issue

if [ ! "x${eth0_addr}" = "x" ] ; then
	echo "The IP Address for eth0 is: ${eth0_addr}" >> /etc/issue
fi
#if [ ! "x${wlan0_addr}" = "x" ] ; then
#	echo "The IP Address for wlan0 is: ${wlan0_addr}" >> /etc/issue
#fi
if [ ! "x${usb0_addr}" = "x" ] ; then
	echo "The IP Address for usb0 is: ${usb0_addr}" >> /etc/issue
fi

#
