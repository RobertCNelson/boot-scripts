#!/bin/sh -e
#

log="BeagleBone-AI:"

#Make sure the cpu_thermal zone is enabled...
if [ -f /sys/class/thermal/thermal_zone0/mode ] ; then
	echo enabled > /sys/class/thermal/thermal_zone0/mode
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

#*.iso priority over *.img
if [ -f /var/local/bb_usb_mass_storage.iso ] ; then
	usb_image_file="/var/local/bb_usb_mass_storage.iso"
elif [ -f /var/local/bb_usb_mass_storage.img ] ; then
	usb_image_file="/var/local/bb_usb_mass_storage.img"
fi

unset dnsmasq_usb0_usb1

dnsmasq_usb0_usb1="enable"

if [ ! "x${usb_image_file}" = "x" ] ; then
	echo "${log} usb_image_file=[`readlink -f ${usb_image_file}`]"
fi

usb_iserialnumber="1234BBBK5678"
usb_iproduct="BeagleBoardX15"
usb_manufacturer="BeagleBoard.org"

#mac address:
#bb_0_mac = eth0 - (from AM57x eeprom)
#bb_1_mac = usb0 (BeagleBone Side) (bb_0_mac + 1)
#bb_2_mac = usb0 (USB host, pc side) (bb_0_mac + 2)
#bb_3_mac = usb1 (BeagleBone Side) (bb_0_mac + 3)
#bb_4_mac = usb1 (USB host, pc side) (bb_0_mac + 4)

mac_address="/proc/device-tree/ocp/ethernet@48484000/slave@48480200/mac-address"
if [ -f ${mac_address} ] && [ -f /usr/bin/hexdump ] ; then
	bb_0_mac=$(hexdump -v -e '1/1 "%02X" ":"' ${mac_address} | sed 's/.$//')

	#Some devices are showing a blank bb_0_mac [00:00:00:00:00:00], let's fix that up...
	if [ "x${bb_0_mac}" = "x00:00:00:00:00:00" ] ; then
		bb_0_mac="1C:BA:8C:A2:ED:68"
	fi
else
	#todo: generate random mac... (this is a development tre board in the lab...)
	bb_0_mac="1C:BA:8C:A2:ED:68"
fi

unset use_cached_bb_mac
if [ -f /etc/bb_0_mac ] ; then
	unset test_bb_0_mac
	test_bb_0_mac=$(cat /etc/bb_0_mac)
	if [ "x${bb_0_mac}" = "x${test_bb_0_mac}" ] ; then
		use_cached_bb_mac="true"
	else
		echo "${bb_0_mac}" > /etc/bb_0_mac || true
	fi
else
	echo "${bb_0_mac}" > /etc/bb_0_mac || true
fi

if [ "x${use_cached_bb_mac}" = "xtrue" ] && [ -f /etc/bb_1_mac ] ; then
	bb_1_mac=$(cat /etc/bb_1_mac)
else
	if [ -f /usr/bin/bc ] ; then
		mac_0_prefix=$(echo ${bb_0_mac} | cut -c 1-14)

		bb_0_6=$(echo ${bb_0_mac} | awk -F ':' '{print $6}')
		#bc cuts off leading zero's, we need ten/ones value
		bb_res=$(echo "obase=16;ibase=16;$bb_0_6 + 101" | bc)

		bb_1_mac=${mac_0_prefix}:$(echo ${bb_res} | cut -c 2-3)
	else
		bb_1_mac="1C:BA:8C:A2:ED:69"
	fi
	echo "${bb_1_mac}" > /etc/bb_1_mac || true
fi

if [ "x${use_cached_bb_mac}" = "xtrue" ] && [ -f /etc/bb_2_mac ] ; then
	bb_2_mac=$(cat /etc/bb_2_mac)
else
	if [ -f /usr/bin/bc ] ; then
		mac_0_prefix=$(echo ${bb_0_mac} | cut -c 1-14)

		bb_0_6=$(echo ${bb_0_mac} | awk -F ':' '{print $6}')
		#bc cuts off leading zero's, we need ten/ones value
		bb_res=$(echo "obase=16;ibase=16;$bb_0_6 + 102" | bc)

		bb_2_mac=${mac_0_prefix}:$(echo ${bb_res} | cut -c 2-3)
	else
		bb_2_mac="1C:BA:8C:A2:ED:70"
	fi
	echo "${bb_2_mac}" > /etc/bb_2_mac || true
fi

if [ "x${use_cached_bb_mac}" = "xtrue" ] && [ -f /etc/bb_3_mac ] ; then
	bb_3_mac=$(cat /etc/bb_3_mac)
else
	if [ -f /usr/bin/bc ] ; then
		mac_0_prefix=$(echo ${bb_0_mac} | cut -c 1-14)

		bb_0_6=$(echo ${bb_0_mac} | awk -F ':' '{print $6}')
		#bc cuts off leading zero's, we need ten/ones value
		bb_res=$(echo "obase=16;ibase=16;$bb_0_6 + 103" | bc)

		bb_3_mac=${mac_0_prefix}:$(echo ${bb_res} | cut -c 2-3)
	else
		bb_3_mac="1C:BA:8C:A2:ED:71"
	fi
	echo "${bb_3_mac}" > /etc/bb_3_mac || true
fi

if [ "x${use_cached_bb_mac}" = "xtrue" ] && [ -f /etc/bb_4_mac ] ; then
	bb_4_mac=$(cat /etc/bb_4_mac)
else
	if [ -f /usr/bin/bc ] ; then
		mac_0_prefix=$(echo ${bb_0_mac} | cut -c 1-14)

		bb_0_6=$(echo ${bb_0_mac} | awk -F ':' '{print $6}')
		#bc cuts off leading zero's, we need ten/ones value
		bb_res=$(echo "obase=16;ibase=16;$bb_0_6 + 104" | bc)

		bb_4_mac=${mac_0_prefix}:$(echo ${bb_res} | cut -c 2-3)
	else
		bb_4_mac="1C:BA:8C:A2:ED:72"
	fi
	echo "${bb_4_mac}" > /etc/bb_4_mac || true
fi

echo "${log} bb_0_mac: [${bb_0_mac}]"
echo "${log} bb_1_mac: [${bb_1_mac}]"
echo "${log} bb_2_mac: [${bb_2_mac}]"
echo "${log} bb_3_mac: [${bb_3_mac}]"
echo "${log} bb_4_mac: [${bb_4_mac}]"

check_getty_tty=$(systemctl is-active serial-getty@ttyGS0.service || true)
if [ "x${check_getty_tty}" = "xinactive" ] ; then
	systemctl restart serial-getty@ttyGS0.service || true
fi

if [ -f /usr/bin/cpufreq-set ] ; then
	echo "${log} cpufreq-set -g powersave"
	/usr/bin/cpufreq-set -g powersave || true
fi
