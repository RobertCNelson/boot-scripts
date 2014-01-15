#!/bin/sh -e
#
# Copyright (c) 2013-2014 Robert Nelson <robertcnelson@gmail.com>
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

if [ ! -d /boot/uboot/debug/ ] ; then
	mkdir -p /boot/uboot/debug/ || true
fi

if [ -e /sys/class/drm/card1/card1-DVI-D-1/edid ] ; then
	if which fbset > /dev/null ; then
		echo "fbset:" > /boot/uboot/debug/edid.txt
		fbset >> /boot/uboot/debug/edid.txt
	fi
	if which parse-edid > /dev/null ; then
		echo "edid:" >> /boot/uboot/debug/edid.txt
		parse-edid /sys/class/drm/card1/card1-DVI-D-1/edid >> /boot/uboot/debug/edid.txt
	fi
fi