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
usb_iproduct="BeagleBoneAI"
usb_manufacturer="BeagleBoard.org"

#mac address:
#bb_0_mac = eth0 - (from AM57x eeprom)
#bb_1_mac = usb0 (BeagleBone Side) (bb_0_mac + 2)
#bb_2_mac = usb0 (USB host, pc side) (bb_0_mac + 3)
#bb_3_mac = usb1 (BeagleBone Side) (bb_0_mac + 4)
#bb_4_mac = usb1 (USB host, pc side) (bb_0_mac + 5)

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
		bb_res=$(echo "obase=16;ibase=16;$bb_0_6 + 102" | bc)

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
		bb_res=$(echo "obase=16;ibase=16;$bb_0_6 + 103" | bc)

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
		bb_res=$(echo "obase=16;ibase=16;$bb_0_6 + 104" | bc)

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
		bb_res=$(echo "obase=16;ibase=16;$bb_0_6 + 105" | bc)

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

#udhcpd gets started at bootup, but we need to wait till g_multi is loaded, and we run it manually...
if [ -f /var/run/udhcpd.pid ] ; then
	echo "${log} [/etc/init.d/udhcpd stop]"
	/etc/init.d/udhcpd stop || true
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

		mkdir -p functions/rndis.usb0
		# first byte of address must be even
		echo ${bb_1_mac} > functions/rndis.usb0/host_addr
		echo ${bb_2_mac} > functions/rndis.usb0/dev_addr

		# Starting with kernel 4.14, we can do this to match Microsoft's built-in RNDIS driver.
		# Earlier kernels require the patch below as a work-around instead:
		# https://github.com/beagleboard/linux/commit/e94487c59cec8ba32dc1eb83900297858fdc590b
		if [ -f functions/rndis.usb0/class ]; then
			echo EF > functions/rndis.usb0/class
			echo 04 > functions/rndis.usb0/subclass
			echo 01 > functions/rndis.usb0/protocol
		fi

		mkdir -p functions/ecm.usb0
		echo ${bb_3_mac} > functions/ecm.usb0/host_addr
		echo ${bb_4_mac} > functions/ecm.usb0/dev_addr

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
		ln -s functions/ecm.usb0 configs/c.1/
		ln -s functions/acm.usb0 configs/c.1/
		if [ "x${has_img_file}" = "xtrue" ] ; then
			ln -s functions/mass_storage.usb0 configs/c.1/
		fi

		#ls /sys/class/udc
		echo 48890000.usb > UDC
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

use_libcomposite

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

		if [ -d /etc/dnsmasq.d/ ] ; then
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
			echo "dhcp-leasefile=/var/run/dnsmasq.leases" >> ${wfile}

			systemctl restart dnsmasq || true
		else
			echo "${log} ERROR: dnsmasq is not installed"
		fi
	fi
fi

check_getty_tty=$(systemctl is-active serial-getty@ttyGS0.service || true)
if [ "x${check_getty_tty}" = "xinactive" ] ; then
	systemctl restart serial-getty@ttyGS0.service || true
fi

if [ -f /usr/bin/cpufreq-set ] ; then
	echo "${log} cpufreq-set -g powersave"
	/usr/bin/cpufreq-set -g powersave || true
fi
