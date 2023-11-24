#!/bin/sh -e
#
# Copyright (c) 2013-2020 Robert Nelson <robertcnelson@gmail.com>
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

log="omap3_beagle:"

if [ -f /etc/rcn-ee.conf ] ; then
	. /etc/rcn-ee.conf
fi

if [ -f /etc/default/bb-boot ] ; then
	. /etc/default/bb-boot

	if [ "x${USB_CONFIGURATION}" = "x" ] ; then
		echo "${log} Updating /etc/default/bb-boot"
		cp -v /opt/scripts/boot/default/bb-boot /etc/default/bb-boot || true
		. /etc/default/bb-boot
	fi
fi

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

#usb0 mass_storage
usb_ms_cdrom=0
usb_ms_ro=1
usb_ms_stall=0
usb_ms_removable=1
usb_ms_nofua=1

#*.iso priority over *.img
if [ -f /var/local/bb_usb_mass_storage.iso ] ; then
	usb_image_file="/var/local/bb_usb_mass_storage.iso"
elif [ -f /var/local/bb_usb_mass_storage.img ] ; then
	usb_image_file="/var/local/bb_usb_mass_storage.img"
fi

if [ ! "x${usb_image_file}" = "x" ] ; then
	echo "${log} usb_image_file=[`readlink -f ${usb_image_file}`]"
fi

usb_iserialnumber="0123456789"
usb_iproduct="BeagleBoard"
usb_manufacturer="BeagleBoard.org"
#udhcpd gets started at bootup, but we need to wait till g_multi is loaded, and we run it manually...
if [ -f /var/run/udhcpd.pid ] ; then
	echo "${log} [/etc/init.d/udhcpd stop]"
	/etc/init.d/udhcpd stop || true
fi

if [ ! -f /etc/systemd/system/getty.target.wants/serial-getty@ttyGS0.service ] ; then
	ln -s /lib/systemd/system/serial-getty@.service /etc/systemd/system/getty.target.wants/serial-getty@ttyGS0.service
fi

run_libcomposite () {
	if [ ! -d /sys/kernel/config/usb_gadget/g_multi/ ] ; then
		echo "${log} Creating g_multi"
		mkdir -p /sys/kernel/config/usb_gadget/g_multi || true
		cd /sys/kernel/config/usb_gadget/g_multi

		echo ${usb_bcdUSB} > bcdUSB
		echo ${usb_idVendor} > idVendor # Linux Foundation
		echo ${usb_idProduct} > idProduct # Multifunction Composite Gadget
		echo ${usb_bcdDevice} > bcdDevice

		#0x409 = english strings...
		mkdir -p strings/0x409

		echo ${usb_iserialnumber} > strings/0x409/serialnumber
		echo ${usb_imanufacturer} > strings/0x409/manufacturer
		cat /proc/device-tree/model > strings/0x409/product

		mkdir -p functions/rndis.usb0
		# first byte of address must be even
		HOST=$(cat /proc/device-tree/model /etc/dogtag |md5sum|sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/')
		SELF=$(cat /proc/device-tree/model /etc/rcn-ee.conf |md5sum|sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/')
		echo "${log} rndis.usb0/host_addr=[${HOST}]"
		echo ${HOST} > functions/rndis.usb0/host_addr
		echo "${log} rndis.usb0/dev_addr=[${SELF}]"
		echo ${SELF} > functions/rndis.usb0/dev_addr
		mkdir -p functions/acm.usb0

		if [ "x${has_img_file}" = "xtrue" ] ; then
			echo "${log} enable USB mass_storage ${usb_image_file}"
			mkdir -p functions/mass_storage.usb0
			echo ${usb_ms_stall} > functions/mass_storage.usb0/stall
			echo ${usb_ms_cdrom} > functions/mass_storage.usb0/lun.0/cdrom
			echo ${usb_ms_nofua} > functions/mass_storage.usb0/lun.0/nofua
			echo ${usb_ms_removable} > functions/mass_storage.usb0/lun.0/removable
			echo ${usb_ms_ro} > functions/mass_storage.usb0/lun.0/ro
			echo ${actual_image_file} > functions/mass_storage.usb0/lun.0/file
		fi

		mkdir -p configs/c.1/strings/0x409
		echo "Multifunction with RNDIS" > configs/c.1/strings/0x409/configuration

		echo 500 > configs/c.1/MaxPower

		ln -s functions/rndis.usb0 configs/c.1/
		ln -s functions/acm.usb0 configs/c.1/
		if [ "x${has_img_file}" = "xtrue" ] ; then
			ln -s functions/mass_storage.usb0 configs/c.1/
		fi

		#ls /sys/class/udc
		echo musb-hdrc.0.auto > UDC
		echo "${log} g_multi Created"

		# Auto-configuring the usb0 network interface:
		$(dirname $0)/autoconfigure_usb0.sh || true
	else
		echo "${log} FIXME: need to bring down g_multi first, before running a second time."
	fi
}

use_libcomposite () {
	echo "${log} use_libcomposite"
	unset has_img_file
	if [ "x${USB_IMAGE_FILE_DISABLED}" = "xyes" ]; then
		echo "${log} usb_image_file disabled by bb-boot config file."
	elif [ -f ${usb_image_file} ] ; then
		actual_image_file=$(readlink -f ${usb_image_file} || true)
		if [ ! "x${actual_image_file}" = "x" ] ; then
			if [ -f ${actual_image_file} ] ; then
				has_img_file="true"
				test_usb_image_file=$(echo ${actual_image_file} | grep .iso || true)
				if [ ! "x${test_usb_image_file}" = "x" ] ; then
					usb_ms_cdrom=1
				fi
			else
				echo "${log} FIXME: no usb_image_file"
			fi
		else
			echo "${log} FIXME: no usb_image_file"
		fi
	fi

	#ls -lha /sys/kernel/*
	#ls -lha /sys/kernel/config/*
#	if [ ! -d /sys/kernel/config/usb_gadget/ ] ; then

	echo "${log} modprobe libcomposite"
	modprobe libcomposite || true
	if [ -d /sys/module/libcomposite ] ; then
		run_libcomposite
	else
		if [ -f /sbin/depmod ] ; then
			/sbin/depmod -a
		fi
		echo "${log} ERROR: [libcomposite didn't load]"
	fi
}

use_libcomposite

if [ -f /usr/bin/amixer ] ; then
	amixer -c0 sset 'DAC1 Digital Fine' 40
	amixer -c0 sset 'Headset' 2
	amixer -c0 sset 'HeadsetL Mixer AudioL1' on
	amixer -c0 sset 'HeadsetR Mixer AudioR1' on
fi

if [ "x${abi}" = "xab" ] ; then
	#Just Cleanup /etc/issue, systemd starts up tty before these are updated...
	sed -i -e '/Address/d' /etc/issue || true
fi

check_getty_tty=$(systemctl is-active serial-getty@ttyGS0.service || true)
if [ "x${check_getty_tty}" = "xinactive" ] ; then
	systemctl restart serial-getty@ttyGS0.service || true
fi

#Disabling Non-Valid Services..
if [ -f /etc/systemd/system/multi-user.target.wants/bb-bbai-tether.service ] ; then
	echo "${log} systemctl: disable bb-bbai-tether.service"
	systemctl disable bb-bbai-tether.service || true
fi
if [ -f /etc/systemd/system/basic.target.wants/cmemk-module.service ] ; then
	echo "${log} systemctl: cmemk-module.service"
	systemctl disable cmemk-module.service || true
fi
if [ -f /etc/systemd/system/basic.target.wants/ti-mct-daemon.service ] ; then
	echo "${log} systemctl: ti-mct-daemon.service"
	systemctl disable ti-mct-daemon.service || true
fi
if [ -f /etc/systemd/system/multi-user.target.wants/robotcontrol.service ] ; then
	echo "${log} systemctl: disable robotcontrol.service"
	systemctl disable robotcontrol.service || true
	rm -f /etc/modules-load.d/robotcontrol_modules.conf || true
fi
if [ -f /etc/systemd/system/multi-user.target.wants/rc_battery_monitor.service ] ; then
	echo "${log} systemctl: rc_battery_monitor.service"
	systemctl disable rc_battery_monitor.service || true
fi
if [ -f /etc/systemd/system/multi-user.target.wants/bb-wl18xx-bluetooth.service ] ; then
	echo "${log} systemctl: bb-wl18xx-bluetooth.service"
	systemctl disable bb-wl18xx-bluetooth.service || true
fi
if [ -f /etc/systemd/system/multi-user.target.wants/bb-wl18xx-wlan0.service ] ; then
	echo "${log} systemctl: bb-wl18xx-wlan0.service"
	systemctl disable bb-wl18xx-wlan0.service || true
fi
#
