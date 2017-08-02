#!/bin/sh -e
#
# Copyright (c) 2013-2017 Robert Nelson <robertcnelson@gmail.com>
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

#legacy support of: 2014-05-14
#Taken care by:
#https://github.com/RobertCNelson/omap-image-builder/blob/master/target/init_scripts/generic-debian.sh#L51
if [ -f /resizerootfs ] ; then
	if [ ! -d /boot/debug/ ] ; then
		mkdir -p /boot/debug/ || true
	fi

	drive=$(cat /resizerootfs)
	if [ "x${drive}" = "x" ] ; then
		drive="/dev/mmcblk0"
	fi

	#FIXME: only good for two partition "/dev/mmcblkXp2" setups...
	resize2fs ${drive}p2 >/boot/debug/resize.log 2>&1
	rm -rf /resizerootfs || true
fi
