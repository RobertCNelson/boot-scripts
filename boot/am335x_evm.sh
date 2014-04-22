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

#Based off:
#https://github.com/beagleboard/meta-beagleboard/blob/master/meta-beagleboard-extras/recipes-support/usb-gadget/gadget-init/g-ether-load.sh

eeprom="/sys/bus/i2c/devices/0-0050/eeprom"

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

SERIAL_NUMBER=$(hexdump -e '8/1 "%c"' ${eeprom} -s 14 -n 2)-$(hexdump -e '8/1 "%c"' ${eeprom} -s 16 -n 12)
ISBLACK=$(hexdump -e '8/1 "%c"' ${eeprom} -s 8 -n 4)

BLACK=""
if [ "x${ISBLACK}" = "xBBBK" ] || [ "x${ISBLACK}" = "xBNLT" ] ; then
	BLACK="Black"
fi

mac_address="/proc/device-tree/ocp/ethernet@4a100000/slave@4a100200/mac-address"
if [ -f ${mac_address} ] ; then
	cpsw_0_mac=$(hexdump -v -e '1/1 "%02X" ":"' ${mac_address} | sed 's/.$//')
fi

mac_address="/proc/device-tree/ocp/ethernet@4a100000/slave@4a100300/mac-address"
if [ -f ${mac_address} ] ; then
	cpsw_1_mac=$(hexdump -v -e '1/1 "%02X" ":"' ${mac_address} | sed 's/.$//')
fi

unset boot_partition
boot_partition=$(LC_ALL=C lsblk -l | grep "/boot/uboot" | awk '{print $1}')
if [ "x${boot_partition}" = "x" ] ; then
	gadget_partition="/dev/mmcblk0p1"
else
	gadget_partition="/dev/${boot_partition}"
fi

modprobe g_multi file=${gadget_partition} cdrom=0 stall=0 removable=1 nofua=1 iSerialNumber=${SERIAL_NUMBER} iManufacturer=Circuitco  iProduct=BeagleBone${BLACK} host_addr=${cpsw_1_mac}

sleep 1

sed -i -e 's:DHCPD_ENABLED="no":#DHCPD_ENABLED="no":g' /etc/default/udhcpd
#Distro default...
deb_udhcpd=$(cat /etc/udhcpd.conf | grep Sample || true)
if [ "${deb_udhcpd}" ] ; then
	mv /etc/udhcpd.conf /etc/udhcpd.conf.bak
fi

if [ ! -f /etc/udhcpd.conf ] ; then
	echo "start      192.168.7.1" > /etc/udhcpd.conf
	echo "end        192.168.7.1" >> /etc/udhcpd.conf
	echo "interface  usb0" >> /etc/udhcpd.conf
	echo "max_leases 1" >> /etc/udhcpd.conf
	echo "option subnet 255.255.255.252" >> /etc/udhcpd.conf
fi
/etc/init.d/udhcpd restart

/sbin/ifconfig usb0 192.168.7.2 netmask 255.255.255.252
/usr/sbin/udhcpd -S /etc/udhcpd.conf

eth0_addr=$(ip addr list eth0 |grep "inet " |cut -d' ' -f6|cut -d/ -f1)
usb0_addr=$(ip addr list usb0 |grep "inet " |cut -d' ' -f6|cut -d/ -f1)
wlan0_addr=$(ip addr list wlan0 |grep "inet " |cut -d' ' -f6|cut -d/ -f1)

sed -i -e '/Address/d' /etc/issue

if [ ! "x${eth0_addr}" = "x" ] ; then
	echo "The IP Address for eth0 is: ${eth0_addr}" >> /etc/issue
fi
if [ ! "x${wlan0_addr}" = "x" ] ; then
	echo "The IP Address for wlan0 is: ${wlan0_addr}" >> /etc/issue
fi
if [ ! "x${usb0_addr}" = "x" ] ; then
	echo "The IP Address for usb0 is: ${usb0_addr}" >> /etc/issue
fi

if [ -f /boot/uboot/flash-eMMC.txt ] ; then
	if [ ! -d /boot/uboot/debug/ ] ; then
		mkdir -p /boot/uboot/debug/ || true
	fi

	if [ -f /opt/scripts/tools/beaglebone-black-eMMC-flasher.sh ] ; then
		/bin/bash /opt/scripts/tools/beaglebone-black-eMMC-flasher.sh >/boot/uboot/debug/flash-eMMC.log 2>&1
	fi
fi

if [ -f /boot/uboot/resizerootfs ] || [ -f /resizerootfs ] ; then
	if [ ! -d /boot/uboot/debug/ ] ; then
		mkdir -p /boot/uboot/debug/ || true
	fi

	drive=$(cat /boot/uboot/resizerootfs)
	if [ "x${drive}" = "x" ] ; then
		drive=$(cat /resizerootfs)
	fi
	if [ "x${drive}" = "x" ] ; then
		drive="/dev/mmcblk0"
	fi

	#FIXME: only good for two partition "/dev/mmcblkXp2" setups...
	resize2fs ${drive}p2 >/boot/uboot/debug/resize.log 2>&1
	rm -rf /boot/uboot/resizerootfs || true
	rm -rf /resizerootfs || true
fi

#
