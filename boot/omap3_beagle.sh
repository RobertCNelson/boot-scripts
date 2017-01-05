#!/bin/sh -e
#
# Copyright (c) 2013-2016 Robert Nelson <robertcnelson@gmail.com>
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
#modprobe configfs
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#Bus 005 Device 014: ID 1d6b:0104 Linux Foundation Multifunction Composite Gadget
usb_gadget="/sys/kernel/config/usb_gadget"

#  idVendor           0x1d6b Linux Foundation
#  idProduct          0x0104 Multifunction Composite Gadget
#  bcdDevice            4.04
#  bcdUSB               2.00

usb_idVendor="0x1d6b"
usb_idProduct="0x0104"
usb_bcdDevice="0x0404"
usb_bcdUSB="0x0200"
usb_serialnr="000000"
usb_manufacturer="BeagleBoard.org"
usb_product="USB Device"

#udhcpd gets started at bootup, but we need to wait till g_multi is loaded, and we run it manually...
if [ -f /var/run/udhcpd.pid ] ; then
	/etc/init.d/udhcpd stop || true
fi

use_libcomposite () {
	modprobe libcomposite || true
	if [ -d /sys/module/libcomposite ] ; then
		if [ -d ${usb_gadget} ] ; then
			if [ ! -d ${usb_gadget}/g_multi/ ] ; then
				mkdir -p ${usb_gadget}/g_multi || true
				cd ${usb_gadget}/g_multi

				echo ${usb_bcdUSB} > bcdUSB

				#Matching lsusb of old g_muilti
				echo 239 > bDeviceClass
				echo 2 > bDeviceSubClass
				echo 1 > bDeviceProtocol

				echo ${usb_idVendor} > idVendor # Linux Foundation
				echo ${usb_idProduct} > idProduct # Multifunction Composite Gadget
				echo ${usb_bcdDevice} > bcdDevice

				#0x409 = english strings...
				mkdir -p strings/0x409

				echo "0123456789" > strings/0x409/serialnumber
				echo ${usb_imanufacturer} > strings/0x409/manufacturer
				cat /proc/device-tree/model > strings/0x409/product

				mkdir -p functions/rndis.usb0
				# first byte of address must be even
				HOST="48:6f:73:74:50:43" # "HostPC"
				SELF="42:61:64:55:53:42" # "BadUSB"
				echo $HOST > functions/ecm.usb0/host_addr
				echo $SELF > functions/ecm.usb0/dev_addr
				mkdir -p functions/acm.usb0

				mkdir -p configs/c.1/strings/0x409
				echo "Multifunction with RNDIS" > configs/c.1/strings/0x409/configuration

				echo 500 > configs/c.1/MaxPower

				ln -s functions/rndis.usb0 configs/c.1/
				ln -s functions/acm.usb0 configs/c.1/

				#ls /sys/class/udc
				echo musb-hdrc.0.auto > UDC

				# Auto-configuring the usb0 network interface:
				$(dirname $0)/autoconfigure_usb0.sh || true
			fi
		fi
	fi
}

use_libcomposite

if [ -d /sys/class/tty/ttyGS0/ ] ; then
	systemctl start serial-getty@ttyGS0.service || true
fi

#Just Cleanup /etc/issue, systemd starts up tty before these are updated...
sed -i -e '/Address/d' /etc/issue

#
