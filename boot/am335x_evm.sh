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

#Based off:
#https://github.com/beagleboard/meta-beagleboard/blob/master/meta-beagleboard-extras/recipes-support/usb-gadget/gadget-init/g-ether-load.sh

disable_connman_dnsproxy () {
	if [ -f /lib/systemd/system/connman.service ] ; then
		#netstat -tapnd
		unset check_connman
		check_connman=$(cat /lib/systemd/system/connman.service | grep ExecStart | grep nodnsproxy || true)
		if [ "x${check_connman}" = "x" ] ; then
			systemctl stop connman.service || true
			sed -i -e 's:connmand -n:connmand -n --nodnsproxy:g' /lib/systemd/system/connman.service || true
			systemctl daemon-reload || true
			systemctl start connman.service || true
		fi
	fi
}

if [ -f /etc/rcn-ee.conf ] ; then
	. /etc/rcn-ee.conf
fi

if [ -f /etc/default/bb-boot ] ; then
	unset USB_NETWORK_DISABLED
	. /etc/default/bb-boot
fi

log="am335x_evm:"

unset detected_capes
detected_capes=$(cat /proc/cmdline | sed 's/ /\n/g' | grep uboot_detected_capes= || true)
if [ ! "x${detected_capes}" = "x" ] ; then
	got_DLPDLCR2000=$(echo ${detected_capes} | grep DLPDLCR2000 || true)
	if [ ! "x${got_DLPDLCR2000}" = "x" ] ; then
		echo "${log} found: DLPDLCR2000 init display"
		i2cset -y 2 0x1b 0x0b 0x00 0x00 0x00 0x00 i || true
		i2cset -y 2 0x1b 0x0c 0x00 0x00 0x00 0x1b i || true
	fi
fi

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
usb_product="USB Device"

#usb0 mass_storage
usb_ms_cdrom=0
usb_ms_ro=1
usb_ms_stall=0
usb_ms_removable=1
usb_ms_nofua=1

#legacy support of: 2014-05-14 (now taken care by the init flasher)
if [ "x${abi}" = "x" ] ; then
	$(dirname $0)/legacy/write_eeprom.sh || true
fi

cleanup_extra_docs () {
	#recovers 82MB of space
	if [ -d /var/cache/doc-beaglebonegreen-getting-started ] ; then
		echo "${log} Cleaning up: /var/cache/doc-beaglebonegreen-getting-started"
		rm -rf /var/cache/doc-beaglebonegreen-getting-started || true
	fi
	if [ -d /var/cache/doc-seeed-bbgw-getting-started ] ; then
		echo "${log} Cleaning up: /var/cache/doc-seeed-bbgw-getting-started"
		rm -rf /var/cache/doc-seeed-bbgw-getting-started || true
	fi
}

#original user:
usb_image_file="/var/local/usb_mass_storage.img"

#*.iso priority over *.img
if [ -f /var/local/bb_usb_mass_storage.iso ] ; then
	usb_image_file="/var/local/bb_usb_mass_storage.iso"
elif [ -f /var/local/bb_usb_mass_storage.img ] ; then
	usb_image_file="/var/local/bb_usb_mass_storage.img"
fi

unset dnsmasq_usb0_usb1
unset blue_fix_uarts

board=$(cat /proc/device-tree/model | sed "s/ /_/g" | tr -d '\000')
case "${board}" in
TI_AM335x_BeagleBone)
	has_wifi="disable"
	cleanup_extra_docs
	dnsmasq_usb0_usb1="enable"
	;;
TI_AM335x_BeagleBone_Black)
	has_wifi="disable"
	cleanup_extra_docs
	dnsmasq_usb0_usb1="enable"
	;;
TI_AM335x_BeagleBone_Black_Wireless)
	has_wifi="enable"
	#recovers 82MB of space
	cleanup_extra_docs
	;;
TI_AM335x_BeagleBone_Blue)
	has_wifi="enable"
	cleanup_extra_docs
#	blue_fix_uarts="enable"
	;;
TI_AM335x_BeagleBone_Green)
	has_wifi="disable"
	unset board_bbgw
	unset board_sbbe
	dnsmasq_usb0_usb1="enable"
	;;
TI_AM335x_BeagleBone_Green_Wireless)
	board_bbgw="enable"
	has_wifi="enable"
	;;
TI_AM335x_BeagleLogic_Standalone)
	has_wifi="disable"
	dnsmasq_usb0_usb1="enable"
	;;
TI_AM335x_P*)
	has_wifi="disable"
	cleanup_extra_docs
	dnsmasq_usb0_usb1="enable"
	;;
SanCloud_BeagleBone_Enhanced)
	board_sbbe="enable"
	has_wifi="enable"
	cleanup_extra_docs
	;;
Octavo_Systems_OSD3358*)
	has_wifi="disable"
	cleanup_extra_docs
	dnsmasq_usb0_usb1="enable"
	;;
TI_AM335x_BeagleBone_Black_RoboticsCape)
	has_wifi="disable"
	cleanup_extra_docs
	dnsmasq_usb0_usb1="enable"
	;;
TI_AM335x_BeagleBone_Black_Wireless_RoboticsCape)
	has_wifi="enable"
	#recovers 82MB of space
	cleanup_extra_docs
	;;
*)
	has_wifi="disable"
	unset board_bbgw
	unset board_sbbe
	;;
esac

if [ ! "x${usb_image_file}" = "x" ] ; then
	echo "${log} usb_image_file=[`readlink -f ${usb_image_file}`]"
fi

usb_iserialnumber="1234BBBK5678"
ISBLACK=""
ISGREEN=""
usb_iproduct="am335x_evm"
usb_imanufacturer="BeagleBoard.org"
wifi_prefix="BeagleBone"

#pre nvmem...
eeprom="/sys/bus/i2c/devices/0-0050/eeprom"
if [ -f ${eeprom} ] && [ -f /usr/bin/hexdump ] ; then
	usb_iserialnumber=$(hexdump -e '8/1 "%c"' ${eeprom} -n 28 | cut -b 17-28)
	ISBLACK=$(hexdump -e '8/1 "%c"' ${eeprom} -n 12 | cut -b 9-12)
	ISGREEN=$(hexdump -e '8/1 "%c"' ${eeprom} -n 19 | cut -b 17-19)
	ISBLACKVARIENT=$(hexdump -e '8/1 "%c"' ${eeprom} -n 16 | cut -b 13-16)
fi

#[PATCH (pre v8) 0/9] Add simple NVMEM Framework via regmap.
eeprom="/sys/class/nvmem/at24-0/nvmem"
if [ -f ${eeprom} ] && [ -f /usr/bin/hexdump ] ; then
	usb_iserialnumber=$(hexdump -e '8/1 "%c"' ${eeprom} -n 28 | cut -b 17-28)
	ISBLACK=$(hexdump -e '8/1 "%c"' ${eeprom} -n 12 | cut -b 9-12)
	ISGREEN=$(hexdump -e '8/1 "%c"' ${eeprom} -n 19 | cut -b 17-19)
	ISBLACKVARIENT=$(hexdump -e '8/1 "%c"' ${eeprom} -n 16 | cut -b 13-16)
fi

#[PATCH v8 0/9] Add simple NVMEM Framework via regmap.
eeprom="/sys/bus/nvmem/devices/at24-0/nvmem"
if [ -f ${eeprom} ] && [ -f /usr/bin/hexdump ] ; then
	usb_iserialnumber=$(hexdump -e '8/1 "%c"' ${eeprom} -n 28 | cut -b 17-28)
	ISBLACK=$(hexdump -e '8/1 "%c"' ${eeprom} -n 12 | cut -b 9-12)
	ISGREEN=$(hexdump -e '8/1 "%c"' ${eeprom} -n 19 | cut -b 17-19)
	ISBLACKVARIENT=$(hexdump -e '8/1 "%c"' ${eeprom} -n 16 | cut -b 13-16)
fi

usb_iproduct="BeagleBone"
if [ "x${ISBLACK}" = "xBBBK" ] || [ "x${ISBLACK}" = "xBNLT" ] ; then
	if [ "x${ISGREEN}" = "xBBG" ] ; then
		usb_imanufacturer="Seeed"
		usb_iproduct="BeagleBoneGreen"
	else
		#FIXME: should be a case statement, on the next varient..
		if [ "x${ISBLACKVARIENT}" = "xGW1A" ] ; then
			usb_imanufacturer="Seeed"
			usb_iproduct="BeagleBoneGreenWireless"
		else
			if [ "x$board_sbbe" = "xenable" ] ; then
				usb_imanufacturer="SanCloud"
				usb_iproduct="BeagleBoneEnhanced"
			else
				usb_iproduct="BeagleBoneBlack"
			fi
		fi
	fi
fi

if [ "x${ISBLACK}" = "xBLGC" ] ; then
	usb_imanufacturer="BeagleLogic"
	usb_iproduct="BeagleLogicStandalone"
fi

#mac address:
#cpsw_0_mac = eth0 - wlan0 (in eeprom)
#cpsw_1_mac = usb0 (BeagleBone Side) (in eeprom)
#cpsw_2_mac = usb0 (USB host, pc side) ((cpsw_0_mac + cpsw_2_mac) /2 )
#cpsw_3_mac = wl18xx (AP) (cpsw_0_mac + 3)
#cpsw_4_mac = usb1 (BeagleBone Side)
#cpsw_5_mac = usb1 (USB host, pc side)

mac_address="/proc/device-tree/ocp/ethernet@4a100000/slave@4a100200/mac-address"
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

unset use_cached_cpsw_mac
if [ -f /etc/cpsw_0_mac ] ; then
	unset test_cpsw_0_mac
	test_cpsw_0_mac=$(cat /etc/cpsw_0_mac)
	if [ "x${cpsw_0_mac}" = "x${test_cpsw_0_mac}" ] ; then
		use_cached_cpsw_mac="true"
	else
		echo "${cpsw_0_mac}" > /etc/cpsw_0_mac || true
	fi
else
	echo "${cpsw_0_mac}" > /etc/cpsw_0_mac || true
fi

if [ "x${use_cached_cpsw_mac}" = "xtrue" ] && [ -f /etc/cpsw_1_mac ] ; then
	cpsw_1_mac=$(cat /etc/cpsw_1_mac)
else
	mac_address="/proc/device-tree/ocp/ethernet@4a100000/slave@4a100300/mac-address"
	if [ -f ${mac_address} ] && [ -f /usr/bin/hexdump ] ; then
		cpsw_1_mac=$(hexdump -v -e '1/1 "%02X" ":"' ${mac_address} | sed 's/.$//')

		#Some devices are showing a blank cpsw_1_mac [00:00:00:00:00:00], let's fix that up...
		if [ "x${cpsw_1_mac}" = "x00:00:00:00:00:00" ] ; then
			if [ -f /usr/bin/bc ] ; then
				mac_0_prefix=$(echo ${cpsw_0_mac} | cut -c 1-14)

				cpsw_0_6=$(echo ${cpsw_0_mac} | awk -F ':' '{print $6}')
				#bc cuts off leading zero's, we need ten/ones value
				cpsw_res=$(echo "obase=16;ibase=16;$cpsw_0_6 + 102" | bc)

				cpsw_1_mac=${mac_0_prefix}:$(echo ${cpsw_res} | cut -c 2-3)
			else
				cpsw_1_mac="1C:BA:8C:A2:ED:70"
			fi
		fi
		echo "${cpsw_1_mac}" > /etc/cpsw_1_mac || true
	else
		#todo: generate random mac...
		cpsw_1_mac="1C:BA:8C:A2:ED:70"
		echo "${cpsw_1_mac}" > /etc/cpsw_1_mac || true
	fi
fi

if [ "x${use_cached_cpsw_mac}" = "xtrue" ] && [ -f /etc/cpsw_2_mac ] ; then
	cpsw_2_mac=$(cat /etc/cpsw_2_mac)
else
	if [ -f /usr/bin/bc ] ; then
		mac_0_prefix=$(echo ${cpsw_0_mac} | cut -c 1-14)

		cpsw_0_6=$(echo ${cpsw_0_mac} | awk -F ':' '{print $6}')
		cpsw_1_6=$(echo ${cpsw_1_mac} | awk -F ':' '{print $6}')

		cpsw_add=$(echo "obase=16;ibase=16;$cpsw_0_6 + $cpsw_1_6" | bc)
		cpsw_div=$(echo "obase=16;ibase=16;$cpsw_add / 2" | bc)
		#bc cuts off leading zero's, we need ten/ones value
		cpsw_res=$(echo "obase=16;ibase=16;$cpsw_div + 100" | bc)

		cpsw_2_mac=${mac_0_prefix}:$(echo ${cpsw_res} | cut -c 2-3)
		echo "${log} uncached cpsw_2_mac: [${cpsw_2_mac}]"
	else
		cpsw_0_last=$(echo ${cpsw_0_mac} | awk -F ':' '{print $6}' | cut -c 2)
		cpsw_1_last=$(echo ${cpsw_1_mac} | awk -F ':' '{print $6}' | cut -c 2)
		mac_0_prefix=$(echo ${cpsw_0_mac} | cut -c 1-16)
		mac_1_prefix=$(echo ${cpsw_1_mac} | cut -c 1-16)
		#if cpsw_0_mac is even, add 1
		case "x${cpsw_0_last}" in
		x0)
			cpsw_2_mac="${mac_0_prefix}1"
			;;
		x2)
			cpsw_2_mac="${mac_0_prefix}3"
			;;
		x4)
			cpsw_2_mac="${mac_0_prefix}5"
			;;
		x6)
			cpsw_2_mac="${mac_0_prefix}7"
			;;
		x8)
			cpsw_2_mac="${mac_0_prefix}9"
			;;
		xA)
			cpsw_2_mac="${mac_0_prefix}B"
			;;
		xC)
			cpsw_2_mac="${mac_0_prefix}D"
			;;
		xE)
			cpsw_2_mac="${mac_0_prefix}F"
			;;
		*)
			#else, subtract 1 from cpsw_1_mac
			case "x${cpsw_1_last}" in
			xF)
				cpsw_2_mac="${mac_1_prefix}E"
				;;
			xD)
				cpsw_2_mac="${mac_1_prefix}C"
				;;
			xB)
				cpsw_2_mac="${mac_1_prefix}A"
				;;
			x9)
				cpsw_2_mac="${mac_1_prefix}8"
				;;
			x7)
				cpsw_2_mac="${mac_1_prefix}6"
				;;
			x5)
				cpsw_2_mac="${mac_1_prefix}4"
				;;
			x3)
				cpsw_2_mac="${mac_1_prefix}2"
				;;
			x1)
				cpsw_2_mac="${mac_1_prefix}0"
				;;
			*)
				#todo: generate random mac...
				cpsw_2_mac="1C:BA:8C:A2:ED:6A"
				;;
			esac
			;;
		esac
	fi
	echo "${cpsw_2_mac}" > /etc/cpsw_2_mac || true
fi

if [ "x${use_cached_cpsw_mac}" = "xtrue" ] && [ -f /etc/cpsw_3_mac ] ; then
	cpsw_3_mac=$(cat /etc/cpsw_3_mac)
else
	if [ -f /usr/bin/bc ] ; then
		mac_0_prefix=$(echo ${cpsw_0_mac} | cut -c 1-14)

		cpsw_0_6=$(echo ${cpsw_0_mac} | awk -F ':' '{print $6}')
		#bc cuts off leading zero's, we need ten/ones value
		cpsw_res=$(echo "obase=16;ibase=16;$cpsw_0_6 + 103" | bc)

		cpsw_3_mac=${mac_0_prefix}:$(echo ${cpsw_res} | cut -c 2-3)
	else
		cpsw_3_mac="1C:BA:8C:A2:ED:71"
	fi
	echo "${cpsw_3_mac}" > /etc/cpsw_3_mac || true
fi

if [ "x${use_cached_cpsw_mac}" = "xtrue" ] && [ -f /etc/cpsw_4_mac ] ; then
	cpsw_4_mac=$(cat /etc/cpsw_4_mac)
else
	if [ -f /usr/bin/bc ] ; then
		mac_0_prefix=$(echo ${cpsw_0_mac} | cut -c 1-14)

		cpsw_0_6=$(echo ${cpsw_0_mac} | awk -F ':' '{print $6}')
		#bc cuts off leading zero's, we need ten/ones value
		cpsw_res=$(echo "obase=16;ibase=16;$cpsw_0_6 + 104" | bc)

		cpsw_4_mac=${mac_0_prefix}:$(echo ${cpsw_res} | cut -c 2-3)
	else
		cpsw_4_mac="1C:BA:8C:A2:ED:72"
	fi
	echo "${cpsw_4_mac}" > /etc/cpsw_4_mac || true
fi

if [ "x${use_cached_cpsw_mac}" = "xtrue" ] && [ -f /etc/cpsw_5_mac ] ; then
	cpsw_5_mac=$(cat /etc/cpsw_5_mac)
else
	if [ -f /usr/bin/bc ] ; then
		mac_0_prefix=$(echo ${cpsw_0_mac} | cut -c 1-14)

		cpsw_0_6=$(echo ${cpsw_0_mac} | awk -F ':' '{print $6}')
		#bc cuts off leading zero's, we need ten/ones value
		cpsw_res=$(echo "obase=16;ibase=16;$cpsw_0_6 + 105" | bc)

		cpsw_5_mac=${mac_0_prefix}:$(echo ${cpsw_res} | cut -c 2-3)
	else
		cpsw_5_mac="1C:BA:8C:A2:ED:73"
	fi
	echo "${cpsw_5_mac}" > /etc/cpsw_5_mac || true
fi

echo "${log} cpsw_0_mac: [${cpsw_0_mac}]"
echo "${log} cpsw_1_mac: [${cpsw_1_mac}]"
echo "${log} cpsw_2_mac: [${cpsw_2_mac}]"
echo "${log} cpsw_3_mac: [${cpsw_3_mac}]"
echo "${log} cpsw_4_mac: [${cpsw_4_mac}]"
echo "${log} cpsw_5_mac: [${cpsw_5_mac}]"

if [ -f /var/lib/connman/settings ] ; then
	wifi_name=$(grep Tethering.Identifier= /var/lib/connman/settings | awk -F '=' '{print $2}' || true)

	#Dont blindly, change Tethering.Identifier as user may have changed it, just match ${wifi_prefix}
	if [ "x${wifi_name}" = "x${wifi_prefix}" ] ; then
		ssid_append=$(echo ${cpsw_0_mac} | cut -b 13-17 | sed 's/://g' || true)
		if [ ! "x${wifi_name}" = "x${wifi_prefix}-${ssid_append}" ] ; then
			if [ ! "x${wifi_name}" = "x${wifi_prefix}-${ssid_append}" ] ; then
				systemctl stop connman.service || true
				sed -i -e 's:Tethering.Identifier='$wifi_name':Tethering.Identifier='$wifi_prefix'-'$ssid_append':g' /var/lib/connman/settings
				systemctl daemon-reload || true
				systemctl restart connman.service || true
			fi
		fi
	fi

	if [ -f /etc/systemd/system/network-online.target.wants/connman-wait-online.service ] ; then
		systemctl disable connman-wait-online.service || true
	fi
fi

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
		echo ${usb_iproduct} > strings/0x409/product

		if [ ! "x${USB_NETWORK_DISABLED}" = "xyes" ]; then
			mkdir -p functions/rndis.usb0
			# first byte of address must be even
			echo ${cpsw_2_mac} > functions/rndis.usb0/host_addr
			echo ${cpsw_1_mac} > functions/rndis.usb0/dev_addr

			# Starting with kernel 4.14, we can do this to match Microsoft's built-in RNDIS driver.
			# Earlier kernels require the patch below as a work-around instead:
			# https://github.com/beagleboard/linux/commit/e94487c59cec8ba32dc1eb83900297858fdc590b
			if [ -f functions/rndis.usb0/class ]; then
				echo EF > functions/rndis.usb0/class
				echo 04 > functions/rndis.usb0/subclass
				echo 01 > functions/rndis.usb0/protocol
			fi

			# Add OS Descriptors for the latest Windows 10 rndiscmp.inf
			# https://answers.microsoft.com/en-us/windows/forum/windows_10-networking-winpc/windows-10-vs-remote-ndis-ethernet-usbgadget-not/cb30520a-753c-4219-b908-ad3d45590447
			# https://www.spinics.net/lists/linux-usb/msg107185.html
			echo 1 > os_desc/use
			echo CD > os_desc/b_vendor_code
			echo MSFT100 > os_desc/qw_sign
			echo "RNDIS" > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
			echo "5162001" > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id

			mkdir -p functions/ecm.usb0
			echo ${cpsw_4_mac} > functions/ecm.usb0/host_addr
			echo ${cpsw_5_mac} > functions/ecm.usb0/dev_addr
		fi

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

		if [ ! "x${USB_NETWORK_DISABLED}" = "xyes" ]; then
			ln -s configs/c.1 os_desc
			mkdir functions/rndis.usb0/os_desc/interface.rndis/Icons
			echo 2 > functions/rndis.usb0/os_desc/interface.rndis/Icons/type
			echo "%SystemRoot%\\system32\\shell32.dll,-233" > functions/rndis.usb0/os_desc/interface.rndis/Icons/data
			mkdir functions/rndis.usb0/os_desc/interface.rndis/Label
			echo 1 > functions/rndis.usb0/os_desc/interface.rndis/Label/type
			echo "BeagleBone USB Ethernet" > functions/rndis.usb0/os_desc/interface.rndis/Label/data

			ln -s functions/rndis.usb0 configs/c.1/
			ln -s functions/ecm.usb0 configs/c.1/
		fi
		ln -s functions/acm.usb0 configs/c.1/
		if [ "x${has_img_file}" = "xtrue" ] ; then
			ln -s functions/mass_storage.usb0 configs/c.1/
		fi

		#ls /sys/class/udc
		#v4.4.x-ti
		if [ -d /sys/class/udc/musb-hdrc.0.auto ] ; then
			echo musb-hdrc.0.auto > UDC
		else
			#v4.9.x-ti
			if [ -d /sys/class/udc/musb-hdrc.0 ] ; then
				echo musb-hdrc.0 > UDC
			fi
		fi

		usb0="enable"
		usb1="enable"
		echo "${log} g_multi Created"
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
	else
		#We don't use a physical partition anymore...
		unset root_drive
		root_drive="$(cat /proc/cmdline | sed 's/ /\n/g' | grep root=UUID= | awk -F 'root=' '{print $2}' || true)"
		if [ ! "x${root_drive}" = "x" ] ; then
			root_drive="$(/sbin/findfs ${root_drive} || true)"
		else
			root_drive="$(cat /proc/cmdline | sed 's/ /\n/g' | grep root= | awk -F 'root=' '{print $2}' || true)"
		fi

		if [ "x${root_drive}" = "x/dev/mmcblk0p1" ] || [ "x${root_drive}" = "x/dev/mmcblk1p1" ] ; then
			echo "${log} FIXME: no valid drive to share over usb"
		else
			actual_image_file="${root_drive%?}1"
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

#	echo
#		echo "${log} libcomposite built-in"
#		run_libcomposite
#	fi
}

g_network="iSerialNumber=${usb_iserialnumber} iManufacturer=${usb_imanufacturer} iProduct=${usb_iproduct} host_addr=${cpsw_2_mac} dev_addr=${cpsw_1_mac}"

usb0_fail () {
	unset usb0
	modprobe g_serial || true
}

#update_initrd () {
#	if [ ! -f /boot/initrd.img-$(uname -r) ] ; then
#		update-initramfs -c -k $(uname -r)
#	else
#		update-initramfs -u -k $(uname -r)
#	fi
#}

g_multi_retry () {
	echo "info: [modprobe g_multi ${g_multi_options}] failed"
#	update_initrd
	modprobe g_multi ${g_multi_options} || usb0_fail
}

g_ether_retry () {
	echo "info: [modprobe g_ether ${g_network}] failed"
#	update_initrd
	modprobe g_ether ${g_network} || usb0_fail
}

g_serial_retry () {
	echo "info: [modprobe g_serial] failed"
#	update_initrd
	modprobe g_serial || true
}

use_old_g_multi () {
	echo "${log} use_old_g_multi"
	#priorty:
	#g_multi
	#g_ether
	#g_serial

	#g_multi: Do we have image file?
	if [ -f ${usb_image_file} ] ; then
		test_usb_image_file=$(echo ${usb_image_file} | grep .iso || true)
		if [ ! "x${test_usb_image_file}" = "x" ] ; then
			usb_ms_cdrom=1
		fi
		g_multi_options="file=${usb_image_file} cdrom=${usb_ms_cdrom} ro=${usb_ms_ro}"
		g_multi_options="${g_multi_options} stall=${usb_ms_stall} removable=${usb_ms_removable}"
		g_multi_options="${g_multi_options} nofua=${usb_ms_nofua} ${g_network}}"
		modprobe g_multi ${g_multi_options} || g_multi_retry
		usb0="enable"
	else
		#g_multi: Do we have a non-rootfs "fat" partition?
		unset root_drive
		root_drive="$(cat /proc/cmdline | sed 's/ /\n/g' | grep root=UUID= | awk -F 'root=' '{print $2}' || true)"
		if [ ! "x${root_drive}" = "x" ] ; then
			root_drive="$(/sbin/findfs ${root_drive} || true)"
		else
			root_drive="$(cat /proc/cmdline | sed 's/ /\n/g' | grep root= | awk -F 'root=' '{print $2}' || true)"
		fi

		if [ "x${root_drive}" = "x/dev/mmcblk0p1" ] || [ "x${root_drive}" = "x/dev/mmcblk1p1" ] ; then
			#g_ether: Do we have udhcpd/dnsmasq?
			if [ -f /usr/sbin/udhcpd ] || [ -f /usr/sbin/dnsmasq ] ; then
				modprobe g_ether ${g_network} || g_ether_retry
				usb0="enable"
			else
				#g_serial: As a last resort...
				modprobe g_serial || g_serial_retry
			fi
		else
			boot_drive="${root_drive%?}1"
			modprobe g_multi file=${boot_drive} cdrom=0 ro=0 stall=0 removable=1 nofua=1 ${g_network} || true
			usb0="enable"
		fi
	fi
}

unset usb0 usb1

#use libcomposite with v4.4.x+ kernel's...
kernel_major=$(uname -r | cut -d. -f1 || true)
kernel_minor=$(uname -r | cut -d. -f2 || true)
compare_major="4"
compare_minor="4"

if [ "${kernel_major}" -lt "${compare_major}" ] ; then
	use_old_g_multi
elif [ "${kernel_major}" -eq "${compare_major}" ] ; then
	if [ "${kernel_minor}" -lt "${compare_minor}" ] ; then
		use_old_g_multi
	else
		use_libcomposite
	fi
else
	use_libcomposite
fi

if [ ! "x${USB_NETWORK_DISABLED}" = "xyes" ]; then
	if [ -f /var/lib/misc/dnsmasq.leases ] ; then
		systemctl stop dnsmasq || true
		rm -rf /var/lib/misc/dnsmasq.leases || true
	fi

	if [ "x${usb0}" = "xenable" ] ; then
		echo "${log} Starting usb0 network"
		# Auto-configuring the usb0 network interface:
		$(dirname $0)/autoconfigure_usb0.sh || true
	fi

	if [ "x${usb1}" = "xenable" ] ; then
		echo "${log} Starting usb1 network"
		# Auto-configuring the usb1 network interface:
		$(dirname $0)/autoconfigure_usb1.sh || true
	fi

	if [ "x${dnsmasq_usb0_usb1}" = "xenable" ] ; then
		if [ -d /sys/kernel/config/usb_gadget ] ; then
			/etc/init.d/udhcpd stop || true

			# do not write if there is a .SoftAp0 file
			if [ -d /etc/dnsmasq.d/ ] ; then
				if [ ! -f /etc/dnsmasq.d/.SoftAp0 ] ; then
					echo "${log} dnsmasq: setting up for usb0/usb1"
					disable_connman_dnsproxy

					wfile="/etc/dnsmasq.d/SoftAp0"
					echo "interface=usb0" > ${wfile}
					echo "interface=usb1" >> ${wfile}
					echo "port=53" >> ${wfile}
					echo "dhcp-authoritative" >> ${wfile}
					echo "domain-needed" >> ${wfile}
					echo "bogus-priv" >> ${wfile}
					echo "expand-hosts" >> ${wfile}
					echo "cache-size=2048" >> ${wfile}
					echo "dhcp-range=usb0,192.168.7.1,192.168.7.1,2m" >> ${wfile}
					echo "dhcp-range=usb1,192.168.6.1,192.168.6.1,2m" >> ${wfile}
					echo "listen-address=127.0.0.1" >> ${wfile}
					echo "listen-address=192.168.7.2" >> ${wfile}
					echo "listen-address=192.168.6.2" >> ${wfile}
					echo "dhcp-option=usb0,3" >> ${wfile}
					echo "dhcp-option=usb0,6" >> ${wfile}
					echo "dhcp-option=usb1,3" >> ${wfile}
					echo "dhcp-option=usb1,6" >> ${wfile}
		#FIXME: why was this added, without connman every ip get's 172.1.8.1????
		#			echo "address=/#/172.1.8.1" >> ${wfile}
					echo "dhcp-leasefile=/var/run/dnsmasq.leases" >> ${wfile}

					systemctl restart dnsmasq || true
				fi
				echo "${log} LOG: dnsmasq is disabled in this script"
			else
				echo "${log} ERROR: dnsmasq is not installed"
			fi
		fi
	fi
fi

#create_ap is now legacy, use connman...
if [ -f /usr/bin/create_ap ] ; then
	if [ "x${has_wifi}" = "xenable" ] ; then
		ifconfig wlan0 down
		ifconfig wlan0 hw ether ${cpsw_0_mac}
		ifconfig wlan0 up || true
		echo "${cpsw_0_mac}" > /etc/wlan0-mac
		systemctl start create_ap &
	fi
fi

#Just Cleanup /etc/issue, systemd starts up tty before these are updated...
sed -i -e '/Address/d' /etc/issue || true

check_getty_tty=$(systemctl is-active serial-getty@ttyGS0.service || true)
if [ "x${check_getty_tty}" = "xinactive" ] ; then
	systemctl restart serial-getty@ttyGS0.service || true
fi

if [ -f /opt/sgx/status ] ; then
	sgx_status=$(cat /opt/sgx/status || true)
	case "${sgx_status}" in
	not_installed)
		if [ -f /opt/sgx/ti-sgx-ti335x-modules-`uname -r`*_armhf.deb ] ; then
			echo "${log} SGX: Installing Modules/ddk"
			dpkg -i /opt/sgx/ti-sgx-ti335x-modules-`uname -r`*_armhf.deb || true
			depmod -a `uname -r` || true
			update-initramfs -uk `uname -r` || true

			dpkg -i /opt/sgx/ti-sgx-ti33x-ddk-um*.deb || true
			echo "installed" > /opt/sgx/status
			sync
		fi
		;;
#	installed)
#		overlay="univ-emmc"
#		;;
	esac
fi

#legacy support of: /sys/kernel/debug mount permissions...
#We now use: debugfs  /sys/kernel/debug  debugfs  mode=755,uid=root,gid=gpio,defaults  0  0
#vs old: debugfs  /sys/kernel/debug  debugfs  defaults  0  0
if [ "x${abi}" = "xab" ] ; then
	if [ -d /sys/kernel/debug ] ; then
		/bin/chmod -R ugo+x /sys/kernel/debug/ || true
		if [ -d /sys/kernel/debug/pinctrl/44e10800.pinmux/ ] ; then
			/bin/chgrp -R gpio /sys/kernel/debug/pinctrl/44e10800.pinmux/ || true
			/bin/chmod -R g=u  /sys/kernel/debug/pinctrl/44e10800.pinmux/ || true
		fi
	fi
fi

#legacy support of: 2014-05-14 (now taken care by the init flasher)
if [ "x${abi}" = "x" ] ; then
	$(dirname $0)/legacy/write_emmc.sh || true
fi

#legacy support of: 2014-05-14 (now taken care by the init flasher)
if [ "x${abi}" = "x" ] ; then
	$(dirname $0)/legacy/old_resize.sh || true
fi

#these are expected to be set by default...
if [ "x${blue_fix_uarts}" = "xenable" ] ; then
	if [ -f /usr/bin/config-pin ] ; then
		test_config_pin=$(/usr/bin/config-pin -q P9.24 2>&1 | grep pinmux | sed "s/ /_/g" | sed "s/\!/_/g" | tr -d '\000' || true)
		if [ "x${test_config_pin}x" = "xP9_24_pinmux_file_not_found_x" ] ; then
			echo "${log} broken /usr/bin/config-pin upgrade bb-cape-overlays"
		else
			echo "${log} config-pin: GPS: Setting P9.21/P9.22 as: uart: [/dev/ttyS2]"
			/usr/bin/config-pin P9.21 uart || true
			/usr/bin/config-pin P9.22 uart || true
			echo "${log} config-pin: UT1: Setting P9.24/P9.26 as: uart: [/dev/ttyS1]"
			/usr/bin/config-pin P9.24 uart || true
			/usr/bin/config-pin P9.26 uart || true
		fi
	fi
fi

unset enable_cape_universal
enable_cape_universal=$(grep 'cape_universal=enable' /proc/cmdline || true)
if [ ! "x${enable_cape_universal}" = "x" ] ; then
	#loading cape-universal...
	if [ -f /sys/devices/platform/bone_capemgr/slots ] ; then

		#cape-universal Exports all pins not used by HDMIN and eMMC (including audio)
		#cape-universaln Exports all pins not used by HDMI and eMMC (no audio pins are exported)
		#cape-univ-emmc Exports pins used by eMMC, load if eMMC is disabled
		#cape-univ-hdmi Exports pins used by HDMI video, load if HDMI is disabled
		#cape-univ-audio Exports pins used by HDMI audio

		unset stop_cape_load
		#Make sure bone_capemgr.uboot_capemgr_enabled=1 wasn't passed to cmdline...
		if [ "x${stop_cape_load}" = "x" ] ; then
			check_enable_partno=$(grep bone_capemgr.uboot_capemgr_enabled=1 /proc/cmdline || true)
			if [ ! "x${check_enable_partno}" = "x" ] ; then
				stop_cape_load="stop"
			fi
		fi

		#Make sure bone_capemgr.enable_partno wasn't passed to cmdline...
		if [ "x${stop_cape_load}" = "x" ] ; then
			check_enable_partno=$(grep bone_capemgr.enable_partno /proc/cmdline || true)
			if [ ! "x${check_enable_partno}" = "x" ] ; then
				stop_cape_load="stop"
			fi
		fi

		#Make sure no custom overlays are loaded...
		if [ "x${stop_cape_load}" = "x" ] ; then
			check_cape_loaded=$(cat /sys/devices/platform/bone_capemgr/slots | awk '{print $3}' | grep 0 | tail -1 || true)
			if [ ! "x${check_cape_loaded}" = "x" ] ; then
				stop_cape_load="stop"
			fi
		fi

		#Make sure we load the correct overlay based on lack/custom dtb's...
		if [ "x${stop_cape_load}" = "x" ] ; then
			unset overlay
			check_dtb=$(cat /boot/uEnv.txt | grep -v '#' | grep dtb | tail -1 | awk -F '=' '{print $2}' || true)
			if [ ! "x${check_dtb}" = "x" ] ; then
				case "${check_dtb}" in
				am335x-boneblack-overlay.dtb)
					overlay="univ-all"
					;;
				am335x-boneblack-emmc-overlay.dtb)
					overlay="univ-emmc"
					;;
				am335x-boneblack-hdmi-overlay.dtb)
					overlay="univ-hdmi"
					;;
				am335x-boneblack-nhdmi-overlay.dtb)
					overlay="univ-nhdmi"
					;;
				am335x-bonegreen-overlay.dtb)
					overlay="univ-all"
					;;
				esac
			else
				machine=$(cat /proc/device-tree/model | sed "s/ /_/g" | tr -d '\000')
				case "${machine}" in
				TI_AM335x_BeagleBone)
					overlay="univ-all"
					;;
				TI_AM335x_BeagleBone_Black_Wireless)
					overlay="cape-universal"
					;;
				TI_AM335x_BeagleBone_Blue)
					unset overlay
					;;
				TI_AM335x_BeagleBone_Black)
					overlay="cape-universal"
					;;
				TI_AM335x_BeagleBone_Green)
					overlay="univ-emmc"
					;;
				TI_AM335x_BeagleBone_Green_Wireless)
					if [ -f /usr/local/lib/node_modules/node-red-node-beaglebone/.bbgw-dont-load ] ; then
						unset overlay
					else
						overlay="univ-bbgw"
					fi
					;;
				esac
			fi
			if [ ! "x${overlay}" = "x" ] ; then
				dtbo="${overlay}-00A0.dtbo"
				if [ -f /lib/firmware/${dtbo} ] ; then
					if [ -f /usr/local/bin/config-pin ] ; then
						/usr/local/bin/config-pin overlay ${overlay} || true
					elif [ -f /usr/bin/config-pin ] ; then
						/usr/bin/config-pin overlay ${overlay} || true
					fi
				fi
			fi
		fi
	fi
fi
#
