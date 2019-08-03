#!/bin/sh -e
#
# Copyright (c) 2013-2017 Robert Nelson <robertcnelson@gmail.com>
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

#Based off:
#https://github.com/beagleboard/meta-beagleboard/blob/master/meta-beagleboard-extras/recipes-support/usb-gadget/gadget-init/g-ether-load.sh

#set -e
#set -x

until [ -d /sys/class/udc/48890000.usb/ ] ; do
	sleep 3
	echo "usb_gadget: waiting for /sys/class/udc/48890000.usb/"
done


#modprobe libcomposite
#echo "device" > /sys/kernel/debug/48890000.usb/mode

usb_gadget="/sys/kernel/config/usb_gadget"

usb_idVendor="0x1d6b"
usb_idProduct="0x0104"
usb_bcdDevice="0x0404"
usb_bcdUSB="0x0300"

#usb0 mass_storage
usb_ms_cdrom=0
#*.iso file...
#usb_ms_cdrom=1
usb_ms_ro=1
usb_ms_stall=0
usb_ms_removable=1
usb_ms_nofua=1

usb_image_file="/var/local/bb_usb_mass_storage.img"
has_img_file="true"

usb_iserialnumber="1234BBBK5678"
usb_iproduct="BeagleBone"
usb_imanufacturer="BeagleBoard.org"

#mac address:
#cpsw_0_mac = eth0 - (from AM57x eeprom)
#cpsw_1_mac = usb0 (BeagleBone Side) (cpsw_0_mac + 2)
#cpsw_2_mac = usb0 (USB host, pc side) (cpsw_0_mac + 3)
#cpsw_3_mac = usb1 (BeagleBone Side) (cpsw_0_mac + 4)
#cpsw_4_mac = usb1 (USB host, pc side) (cpsw_0_mac + 5)

mac_address="/proc/device-tree/ocp/ethernet@48484000/slave@48480200/mac-address"
if [ -f ${mac_address} ] && [ -f /usr/bin/hexdump ] ; then
	cpsw_0_mac=$(hexdump -v -e '1/1 "%02X" ":"' ${mac_address} | sed 's/.$//')

	#Some devices are showing a blank cpsw_0_mac [00:00:00:00:00:00], let's fix that up...
	if [ "x${cpsw_0_mac}" = "x00:00:00:00:00:00" ] ; then
		cpsw_0_mac="1C:BA:8C:A2:ED:68"
	fi
else
	#todo: generate random mac... (this is a development tre board in the lab...)
	cpsw_0_mac="1C:BA:8C:A2:ED:68"
fi

unset use_cached_bb_mac
if [ -f /etc/cpsw_0_mac ] ; then
	unset test_cpsw_0_mac
	test_cpsw_0_mac=$(cat /etc/cpsw_0_mac)
	if [ "x${cpsw_0_mac}" = "x${test_cpsw_0_mac}" ] ; then
		use_cached_bb_mac="true"
	else
		echo "${cpsw_0_mac}" > /etc/cpsw_0_mac || true
	fi
else
	echo "${cpsw_0_mac}" > /etc/cpsw_0_mac || true
fi

if [ "x${use_cached_bb_mac}" = "xtrue" ] && [ -f /etc/cpsw_1_mac ] ; then
	cpsw_1_mac=$(cat /etc/cpsw_1_mac)
else
	if [ -f /usr/bin/bc ] ; then
		mac_0_prefix=$(echo ${cpsw_0_mac} | cut -c 1-14)

		cpsw_0_6=$(echo ${cpsw_0_mac} | awk -F ':' '{print $6}')
		#bc cuts off leading zero's, we need ten/ones value
		bb_res=$(echo "obase=16;ibase=16;$cpsw_0_6 + 102" | bc)

		cpsw_1_mac=${mac_0_prefix}:$(echo ${bb_res} | cut -c 2-3)
	else
		cpsw_1_mac="1C:BA:8C:A2:ED:69"
	fi
	echo "${cpsw_1_mac}" > /etc/cpsw_1_mac || true
fi

if [ "x${use_cached_bb_mac}" = "xtrue" ] && [ -f /etc/cpsw_2_mac ] ; then
	cpsw_2_mac=$(cat /etc/cpsw_2_mac)
else
	if [ -f /usr/bin/bc ] ; then
		mac_0_prefix=$(echo ${cpsw_0_mac} | cut -c 1-14)

		cpsw_0_6=$(echo ${cpsw_0_mac} | awk -F ':' '{print $6}')
		#bc cuts off leading zero's, we need ten/ones value
		bb_res=$(echo "obase=16;ibase=16;$cpsw_0_6 + 103" | bc)

		cpsw_2_mac=${mac_0_prefix}:$(echo ${bb_res} | cut -c 2-3)
	else
		cpsw_2_mac="1C:BA:8C:A2:ED:70"
	fi
	echo "${cpsw_2_mac}" > /etc/cpsw_2_mac || true
fi

if [ "x${use_cached_bb_mac}" = "xtrue" ] && [ -f /etc/cpsw_3_mac ] ; then
	cpsw_3_mac=$(cat /etc/cpsw_3_mac)
else
	if [ -f /usr/bin/bc ] ; then
		mac_0_prefix=$(echo ${cpsw_0_mac} | cut -c 1-14)

		cpsw_0_6=$(echo ${cpsw_0_mac} | awk -F ':' '{print $6}')
		#bc cuts off leading zero's, we need ten/ones value
		bb_res=$(echo "obase=16;ibase=16;$cpsw_0_6 + 104" | bc)

		cpsw_3_mac=${mac_0_prefix}:$(echo ${bb_res} | cut -c 2-3)
	else
		cpsw_3_mac="1C:BA:8C:A2:ED:71"
	fi
	echo "${cpsw_3_mac}" > /etc/cpsw_3_mac || true
fi

if [ "x${use_cached_bb_mac}" = "xtrue" ] && [ -f /etc/cpsw_4_mac ] ; then
	cpsw_4_mac=$(cat /etc/cpsw_4_mac)
else
	if [ -f /usr/bin/bc ] ; then
		mac_0_prefix=$(echo ${cpsw_0_mac} | cut -c 1-14)

		cpsw_0_6=$(echo ${cpsw_0_mac} | awk -F ':' '{print $6}')
		#bc cuts off leading zero's, we need ten/ones value
		bb_res=$(echo "obase=16;ibase=16;$cpsw_0_6 + 105" | bc)

		cpsw_4_mac=${mac_0_prefix}:$(echo ${bb_res} | cut -c 2-3)
	else
		cpsw_4_mac="1C:BA:8C:A2:ED:72"
	fi
	echo "${cpsw_4_mac}" > /etc/cpsw_4_mac || true
fi

echo "${log} cpsw_0_mac: [${cpsw_0_mac}]"
echo "${log} cpsw_1_mac: [${cpsw_1_mac}]"
echo "${log} cpsw_2_mac: [${cpsw_2_mac}]"
echo "${log} cpsw_3_mac: [${cpsw_3_mac}]"
echo "${log} cpsw_4_mac: [${cpsw_4_mac}]"

if [ ! -f /etc/systemd/system/getty.target.wants/serial-getty@ttyGS0.service ] ; then
	ln -s /lib/systemd/system/serial-getty@.service /etc/systemd/system/getty.target.wants/serial-getty@ttyGS0.service
fi

	echo "${log} Creating g_multi"
	mkdir -p /sys/kernel/config/usb_gadget/g_multi
	cd /sys/kernel/config/usb_gadget/g_multi

	echo ${usb_bcdUSB} > bcdUSB
	echo ${usb_idVendor} > idVendor # Linux Foundation
	echo ${usb_idProduct} > idProduct # Multifunction Composite Gadget
	echo ${usb_bcdDevice} > bcdDevice

	#0x409 = english strings...
	mkdir -p strings/0x409

	echo ${usb_iserialnumber} > strings/0x409/serialnumber
	echo ${usb_imanufacturer} > strings/0x409/manufacturer
	echo ${usb_iproduct} > strings/0x409/product

	if [ "x${has_img_file}" = "xtrue" ] ; then
		echo "${log} enable USB mass_storage ${usb_image_file}"
		mkdir -p functions/mass_storage.usb0
		echo ${usb_ms_stall} > functions/mass_storage.usb0/stall
		echo ${usb_ms_cdrom} > functions/mass_storage.usb0/lun.0/cdrom
		echo ${usb_ms_nofua} > functions/mass_storage.usb0/lun.0/nofua
		echo ${usb_ms_removable} > functions/mass_storage.usb0/lun.0/removable
		echo ${usb_ms_ro} > functions/mass_storage.usb0/lun.0/ro
		echo ${usb_image_file} > functions/mass_storage.usb0/lun.0/file
	fi

	if [ true ]; then
		mkdir -p functions/rndis.usb0
		# first byte of address must be even
		echo ${cpsw_1_mac} > functions/rndis.usb0/host_addr
		echo ${cpsw_2_mac} > functions/rndis.usb0/dev_addr

		# Starting with kernel 4.14, we can do this to match Microsoft's built-in RNDIS driver.
		# Earlier kernels require the patch below as a work-around instead:
		# https://github.com/beagleboard/linux/commit/e94487c59cec8ba32dc1eb83900297858fdc590b
		#echo 0xEF > functions/rndis.usb0/class
		#echo 0x04 > functions/rndis.usb0/subclass
		#echo 0x01 > functions/rndis.usb0/protocol

		# Add OS Descriptors for the latest Windows 10 rndiscmp.inf
		# https://answers.microsoft.com/en-us/windows/forum/windows_10-networking-winpc/windows-10-vs-remote-ndis-ethernet-usbgadget-not/cb30520a-753c-4219-b908-ad3d45590447
		# https://www.spinics.net/lists/linux-usb/msg107185.html
		echo 1 > os_desc/use
		echo 0xCD > os_desc/b_vendor_code
		echo MSFT100 > os_desc/qw_sign
		echo "RNDIS" > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
		echo "5162001" > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id

		mkdir -p configs/c.1
		ln -s configs/c.1 os_desc
		mkdir functions/rndis.usb0/os_desc/interface.rndis/Icons
		echo 2 > functions/rndis.usb0/os_desc/interface.rndis/Icons/type
		echo "%SystemRoot%\\system32\\shell32.dll,-233" > functions/rndis.usb0/os_desc/interface.rndis/Icons/data
		mkdir functions/rndis.usb0/os_desc/interface.rndis/Label
		echo 1 > functions/rndis.usb0/os_desc/interface.rndis/Label/type
		echo "BeagleBone USB Ethernet" > functions/rndis.usb0/os_desc/interface.rndis/Label/data

		mkdir -p functions/ecm.usb0
		echo ${cpsw_3_mac} > functions/ecm.usb0/host_addr
		echo ${cpsw_4_mac} > functions/ecm.usb0/dev_addr
	fi

	mkdir -p functions/acm.usb0

	mkdir -p configs/c.1/strings/0x409
	echo "Multifunction with RNDIS" > configs/c.1/strings/0x409/configuration


	echo 500 > configs/c.1/MaxPower

	if [ "x${has_img_file}" = "xtrue" ] ; then
		ln -s functions/mass_storage.usb0 configs/c.1/
	fi

	if [ true ]; then
		ln -s functions/rndis.usb0 configs/c.1/
		ln -s functions/ecm.usb0 configs/c.1/
		ln -s functions/acm.usb0 configs/c.1/
	fi

	echo 48890000.usb > UDC


