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

if [ -f /etc/rcn-ee.conf ] ; then
	. /etc/rcn-ee.conf
fi

#legacy support of: 2014-05-14
if [ "x${abi}" = "x" ] ; then
	eeprom="/sys/bus/i2c/devices/0-0050/eeprom"
	#taken care by the init flasher
	#Flash BeagleBone Black's eeprom:
	if [ -f /boot/uboot/flash-eMMC.txt ] ; then
		eeprom_location=$(ls /sys/devices/ocp.*/44e0b000.i2c/i2c-0/0-0050/eeprom 2> /dev/null)
		eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -s 5 -n 3)
		if [ "x${eeprom_header}" = "x335" ] ; then
			echo "Valid EEPROM header found"
		else
			echo "Invalid EEPROM header detected"
			if [ -f /opt/scripts/device/bone/bbb-eeprom.dump ] ; then
				if [ ! "x${eeprom_location}" = "x" ] ; then
					echo "Adding header to EEPROM"
					dd if=/opt/scripts/device/bone/bbb-eeprom.dump of=${eeprom_location}
					sync
					#We have to reboot, to load eMMC cape
					reboot
					#We shouldnt hit this...
					exit
				fi
			fi
		fi
	fi
fi

cleanup_extra_docs () {
	#recovers 82MB of space
	if [ -d /var/cache/doc-beaglebonegreen-getting-started ] ; then
		rm -rf /var/cache/doc-beaglebonegreen-getting-started || true
	fi
	if [ -d /var/cache/doc-seeed-bbgw-getting-started ] ; then
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

board=$(cat /proc/device-tree/model | sed "s/ /_/g")
case "${board}" in
TI_AM335x_BeagleBone)
	has_wifi="disable"
	has_ethernet="enable"
	cleanup_extra_docs
	;;
TI_AM335x_BeagleBone_Black)
	has_wifi="disable"
	has_ethernet="enable"
	cleanup_extra_docs
	;;
TI_AM335x_BeagleBone_Black_Wireless)
	has_wifi="enable"
	has_ethernet="disable"
	#recovers 82MB of space
	cleanup_extra_docs
	;;
TI_AM335x_BeagleBone_Blue)
	has_wifi="enable"
	has_ethernet="disable"
	cleanup_extra_docs
	;;
TI_AM335x_BeagleBone_Green)
	has_wifi="disable"
	has_ethernet="enable"
	unset board_bbgw
	unset board_sbbe
	if [ -f /var/local/bbg_usb_mass_storage.iso ] ; then
		usb_image_file="/var/local/bbg_usb_mass_storage.iso"
	elif [ -f /var/local/bbg_usb_mass_storage.img ] ; then
		usb_image_file="/var/local/bbg_usb_mass_storage.img"
	fi
	;;
TI_AM335x_BeagleBone_Green_Wireless)
	board_bbgw="enable"
	has_wifi="enable"
	has_ethernet="disable"
	if [ -f /var/local/bbgw_usb_mass_storage.iso ] ; then
		usb_image_file="/var/local/bbgw_usb_mass_storage.iso"
	elif [ -f /var/local/bbgw_usb_mass_storage.img ] ; then
		usb_image_file="/var/local/bbgw_usb_mass_storage.img"
	fi
	;;
SanCloud_BeagleBone_Enhanced)
	board_sbbe="enable"
	has_wifi="enable"
	has_ethernet="enable"
	cleanup_extra_docs
	;;
*)
	has_wifi="disable"
	has_ethernet="enable"
	unset board_bbgw
	unset board_sbbe
	;;
esac

SERIAL_NUMBER="1234BBBK5678"
ISBLACK=""
ISGREEN=""
PRODUCT="am335x_evm"
manufacturer="BeagleBoard.org"
wifi_prefix="BeagleBone"

#pre nvmem...
eeprom="/sys/bus/i2c/devices/0-0050/eeprom"
if [ -f ${eeprom} ] ; then
	SERIAL_NUMBER=$(hexdump -e '8/1 "%c"' ${eeprom} -n 28 | cut -b 17-28)
	ISBLACK=$(hexdump -e '8/1 "%c"' ${eeprom} -n 12 | cut -b 9-12)
	ISGREEN=$(hexdump -e '8/1 "%c"' ${eeprom} -n 19 | cut -b 17-19)
	ISBLACKVARIENT=$(hexdump -e '8/1 "%c"' ${eeprom} -n 16 | cut -b 13-16)
fi

#[PATCH (pre v8) 0/9] Add simple NVMEM Framework via regmap.
eeprom="/sys/class/nvmem/at24-0/nvmem"
if [ -f ${eeprom} ] ; then
	SERIAL_NUMBER=$(hexdump -e '8/1 "%c"' ${eeprom} -n 28 | cut -b 17-28)
	ISBLACK=$(hexdump -e '8/1 "%c"' ${eeprom} -n 12 | cut -b 9-12)
	ISGREEN=$(hexdump -e '8/1 "%c"' ${eeprom} -n 19 | cut -b 17-19)
	ISBLACKVARIENT=$(hexdump -e '8/1 "%c"' ${eeprom} -n 16 | cut -b 13-16)
fi

#[PATCH v8 0/9] Add simple NVMEM Framework via regmap.
eeprom="/sys/bus/nvmem/devices/at24-0/nvmem"
if [ -f ${eeprom} ] ; then
	SERIAL_NUMBER=$(hexdump -e '8/1 "%c"' ${eeprom} -n 28 | cut -b 17-28)
	ISBLACK=$(hexdump -e '8/1 "%c"' ${eeprom} -n 12 | cut -b 9-12)
	ISGREEN=$(hexdump -e '8/1 "%c"' ${eeprom} -n 19 | cut -b 17-19)
	ISBLACKVARIENT=$(hexdump -e '8/1 "%c"' ${eeprom} -n 16 | cut -b 13-16)
fi

PRODUCT="BeagleBone"
if [ "x${ISBLACK}" = "xBBBK" ] || [ "x${ISBLACK}" = "xBNLT" ] ; then
	if [ "x${ISGREEN}" = "xBBG" ] ; then
		manufacturer="Seeed"
		PRODUCT="BeagleBoneGreen"
	else
		#FIXME: should be a case statement, on the next varient..
		if [ "x${ISBLACKVARIENT}" = "xGW1A" ] ; then
			manufacturer="Seeed"
			PRODUCT="BeagleBoneGreenWireless"
		else
			if [ "x$board_sbbe" = "xenable" ] ; then
				manufacturer="SanCloud"
				PRODUCT="BeagleBoneEnhanced"
			else
				PRODUCT="BeagleBoneBlack"
			fi
		fi
	fi
fi

mac_address="/proc/device-tree/ocp/ethernet@4a100000/slave@4a100200/mac-address"
if [ -f ${mac_address} ] ; then
	cpsw_0_mac=$(hexdump -v -e '1/1 "%02X" ":"' ${mac_address} | sed 's/.$//')
else
	#todo: generate random mac... (this is a development tre board in the lab...)
	cpsw_0_mac="1c:ba:8c:a2:ed:68"
fi

if [ -f /var/lib/connman/settings ] ; then
	wifi_name=$(grep Tethering.Identifier= /var/lib/connman/settings | awk -F '=' '{print $2}' || true)

	#Dont blindly, change Tethering.Identifier as user may have changed it, just match ${wifi_prefix}
	if [ "x${wifi_name}" = "x${wifi_prefix}" ] ; then
		ssid_append=$(echo ${cpsw_0_mac} | cut -b 13-17 | sed 's/://g' || true)
		if [ ! "x${wifi_name}" = "x${wifi_prefix}-${ssid_append}" ] ; then
			if [ ! "x${wifi_name}" = "x${wifi_prefix}-${ssid_append}" ] ; then
				sed -i -e 's:Tethering.Identifier='$wifi_name':Tethering.Identifier='$wifi_prefix'-'$ssid_append':g' /var/lib/connman/settings
				systemctl restart connman.service || true
			fi
		fi
	fi

	if [ -f /etc/systemd/system/network-online.target.wants/connman-wait-online.service ] ; then
		systemctl disable connman-wait-online.service || true
	fi
fi

mac_address="/proc/device-tree/ocp/ethernet@4a100000/slave@4a100300/mac-address"
if [ -f ${mac_address} ] ; then
	cpsw_1_mac=$(hexdump -v -e '1/1 "%02X" ":"' ${mac_address} | sed 's/.$//')
else
	#todo: generate random mac...
	cpsw_1_mac="1c:ba:8c:a2:ed:69"
fi

#Determine cpsw_2_mac assumed to be allocated between cpsw_0_mac and cpsw_1_mac
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
		cpsw_2_mac="1c:ba:8c:a2:ed:6a"
		;;
	esac
	;;
esac

echo "cpsw_0_mac: [${cpsw_0_mac}]"
echo "cpsw_1_mac: [${cpsw_1_mac}]"
echo "cpsw_2_mac: [${cpsw_2_mac}]"

#hack till bbgw firmware is decided on..
if [ -d /sys/devices/platform/ocp/47810000.mmc/mmc_host/mmc2/mmc2:0001/mmc2:0001:2/ ] ; then
	board_bbgw="enable"
fi

g_network="iSerialNumber=${SERIAL_NUMBER} iManufacturer=${manufacturer} iProduct=${PRODUCT} host_addr=${cpsw_2_mac} dev_addr=${cpsw_1_mac}"

#priorty:
#g_multi
#g_ether
#g_serial

unset usb0
unset ttyGS0

#g_multi: Do we have image file?
if [ -f ${usb_image_file} ] ; then
	test_usb_image_file=$(echo ${usb_image_file} | grep .iso || true)
	if [ ! "x${test_usb_image_file}" = "x" ] ; then
		modprobe g_multi file=${usb_image_file} cdrom=1 ro=1 stall=0 removable=1 nofua=1 ${g_network} || true
	else
		modprobe g_multi file=${usb_image_file} cdrom=0 ro=1 stall=0 removable=1 nofua=1 ${g_network} || true
	fi
	usb0="enable"
	ttyGS0="enable"
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
			modprobe g_ether ${g_network} || true
			usb0="enable"
		else
			#g_serial: As a last resort...
			modprobe g_serial || true
			ttyGS0="enable"
		fi
	else
		boot_drive="${root_drive%?}1"
		modprobe g_multi file=${boot_drive} cdrom=0 ro=0 stall=0 removable=1 nofua=1 ${g_network} || true
		usb0="enable"
		ttyGS0="enable"
	fi

fi

if [ "x${usb0}" = "xenable" ] ; then
	# Auto-configuring the usb0 network interface:
	$(dirname $0)/autoconfigure_usb0.sh
fi

if [ "x${ttyGS0}" = "xenable" ] ; then
	systemctl start serial-getty@ttyGS0.service || true
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

unset eth0_addr
if [ "x${has_ethernet}" = "xenable" ] ; then
	eth0_addr=$(ip addr list eth0 |grep "inet " |cut -d' ' -f6|cut -d/ -f1 2>/dev/null || true)
fi
if [ "x${usb0}" = "xenable" ] ; then
	unset usb0_addr
	usb0_addr=$(ip addr list usb0 |grep "inet " |cut -d' ' -f6|cut -d/ -f1 2>/dev/null || true)
fi
unset wlan0_addr
if [ "x${has_wifi}" = "xenable" ] ; then
	wlan0_addr=$(ip addr list wlan0 |grep "inet " |cut -d' ' -f6|cut -d/ -f1 2>/dev/null || true)
fi

sed -i -e '/Address/d' /etc/issue

if [ ! "x${eth0_addr}" = "x" ] ; then
	echo "The IP Address for eth0 is: ${eth0_addr}" >> /etc/issue
fi
if [ ! "x${wlan0_addr}" = "x" ] ; then
	echo "The IP Address for wlan0 is: ${wlan0_addr}" >> /etc/issue
fi
if [ "x${usb0}" = "xenable" ] ; then
	if [ ! "x${usb0_addr}" = "x" ] ; then
		echo "The IP Address for usb0 is: ${usb0_addr}" >> /etc/issue
	fi
fi

#Fighting Race conditions with lcd overlays...

unset test_service
test_service=$(systemctl is-enabled lightdm.service || true)
if [ "x${test_service}" = "xenabled" ] ; then
	test_service=$(systemctl is-failed lightdm.service || true)

	if [ "x${test_service}" = "xinactive" ] ; then
		systemctl restart lightdm || true
	fi
fi

#legacy support of: 2014-05-14
if [ "x${abi}" = "x" ] ; then
	#taken care by the init flasher
	if [ -f /boot/uboot/flash-eMMC.txt ] ; then
		if [ ! -d /boot/uboot/debug/ ] ; then
			mkdir -p /boot/uboot/debug/ || true
		fi

		if [ -f /opt/scripts/tools/beaglebone-black-eMMC-flasher.sh ] ; then
			/bin/bash /opt/scripts/tools/beaglebone-black-eMMC-flasher.sh >/boot/uboot/debug/flash-eMMC.log 2>&1
		fi
	fi
fi

#legacy support of: 2014-05-14
if [ "x${abi}" = "x" ] ; then
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
				machine=$(cat /proc/device-tree/model | sed "s/ /_/g")
				case "${machine}" in
				TI_AM335x_BeagleBone)
					overlay="univ-all"
					;;
				TI_AM335x_BeagleBone_Black_Wireless)
					overlay="cape-universaln"
					;;
				TI_AM335x_BeagleBone_Blue)
					unset overlay
					;;
				TI_AM335x_BeagleBone_Black)
					overlay="cape-universaln"
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
						config-pin overlay ${overlay} || true
					fi
				fi
			fi
		fi
	fi
fi
#
