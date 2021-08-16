#!/bin/sh -e
#

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

log="BeagleBone-AI:"

if [ -f /etc/rcn-ee.conf ] ; then
	. /etc/rcn-ee.conf
fi

if [ -f /etc/default/bb-boot ] ; then
	unset USB_NETWORK_DISABLED

	. /etc/default/bb-boot

	if [ "x${USB_CONFIGURATION}" = "x" ] ; then
		echo "${log} Updating /etc/default/bb-boot"
		cp -v /opt/scripts/boot/default/bb-boot /etc/default/bb-boot || true
		. /etc/default/bb-boot
	fi
fi

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
#*.iso file...
#usb_ms_cdrom=1
usb_ms_ro=1
usb_ms_stall=0
usb_ms_removable=1
usb_ms_nofua=1

usb_image_file="/var/local/bb_usb_mass_storage.img"
has_img_file="true"

#Broken today...
usb_serial_gadget="disable"

usb_iserialnumber="1234BBBK5678"
#usb_iproduct="BeagleBoneAI"
usb_iproduct="BeagleBone"
usb_imanufacturer="BeagleBoard.org"

#mac address:
#cpsw_0_mac = eth0 - (from AM57x eeprom)
#cpsw_1_mac = usb0 (BeagleBone Side)
#cpsw_2_mac = usb0 (USB host, pc side)
#cpsw_3_mac = usb1 (BeagleBone Side)
#cpsw_4_mac = usb1 (USB host, pc side)

mac_address="/proc/device-tree/ocp/ethernet@48484000/slave@48480200/mac-address"
if [ -f ${mac_address} ] && [ -f /usr/bin/hexdump ] ; then
	mac_addr0=$(hexdump -v -e '1/1 "%02X" ":"' ${mac_address} | sed 's/.$//')

	#Some devices are showing a blank mac_addr0 [00:00:00:00:00:00], let's fix that up...
	if [ "x${mac_addr0}" = "x00:00:00:00:00:00" ] ; then
		mac_addr0="1C:BA:8C:A2:ED:68"
	fi
else
	#todo: generate random mac... (this is a development tre board in the lab...)
	mac_addr0="1C:BA:8C:A2:ED:68"
fi

mac_addr0_octet_1_5=$(echo ${mac_addr0} | cut -c 1-14)
mac_addr0_octet_6=$(echo ${mac_addr0} | awk -F ':' '{print $6}')

if [ -f /usr/bin/bb_generate_mac.sh ] ; then
	/usr/bin/bb_generate_mac.sh --mac ${mac_addr0}
	cpsw_1_mac=$(cat /etc/cpsw_1_mac)
	cpsw_2_mac=$(cat /etc/cpsw_2_mac)
	cpsw_3_mac=$(cat /etc/cpsw_3_mac)
	cpsw_4_mac=$(cat /etc/cpsw_4_mac)
	cpsw_5_mac=$(cat /etc/cpsw_5_mac)
else
	unset use_cached_mac_addr
	if [ -f /etc/cpsw_0_mac ] ; then
		unset test_cpsw_0_mac
		test_cpsw_0_mac=$(cat /etc/cpsw_0_mac)
		if [ "x${mac_addr0}" = "x${test_cpsw_0_mac}" ] ; then
			use_cached_mac_addr="true"
		else
			echo "${mac_addr0}" > /etc/cpsw_0_mac || true
		fi
	else
		echo "${mac_addr0}" > /etc/cpsw_0_mac || true
	fi

	if [ "x${use_cached_mac_addr}" = "xtrue" ] && [ -f /etc/cpsw_1_mac ] ; then
		mac_addr1=$(cat /etc/cpsw_1_mac)
	else
		if [ -f /usr/bin/bc ] ; then
			#bc cuts off leading zero's, we need ten/ones value
			new_octet_6=$(echo "obase=16;ibase=16;$mac_addr0_octet_6 + 102" | bc)

			mac_addr1=${mac_addr0_octet_1_5}:$(echo ${new_octet_6} | cut -c 2-3)
		else
			mac_addr1="1C:BA:8C:A2:ED:69"
		fi
		echo "${mac_addr1}" > /etc/cpsw_1_mac || true
	fi

	if [ "x${use_cached_mac_addr}" = "xtrue" ] && [ -f /etc/cpsw_2_mac ] ; then
		mac_addr2=$(cat /etc/cpsw_2_mac)
	else
		if [ -f /usr/bin/bc ] ; then
			#bc cuts off leading zero's, we need ten/ones value
			new_octet_6=$(echo "obase=16;ibase=16;$cpsw_0_6 + 103" | bc)

			mac_addr2=${mac_addr0_octet_1_5}:$(echo ${new_octet_6} | cut -c 2-3)
		else
			mac_addr2="1C:BA:8C:A2:ED:70"
		fi
		echo "${mac_addr2}" > /etc/cpsw_2_mac || true
	fi

	if [ "x${use_cached_mac_addr}" = "xtrue" ] && [ -f /etc/cpsw_3_mac ] ; then
		mac_addr3=$(cat /etc/cpsw_3_mac)
	else
		if [ -f /usr/bin/bc ] ; then
			#bc cuts off leading zero's, we need ten/ones value
			new_octet_6=$(echo "obase=16;ibase=16;$cpsw_0_6 + 104" | bc)

			mac_addr3=${mac_addr0_octet_1_5}:$(echo ${new_octet_6} | cut -c 2-3)
		else
			mac_addr3="1C:BA:8C:A2:ED:71"
		fi
		echo "${mac_addr3}" > /etc/cpsw_3_mac || true
	fi

	if [ "x${use_cached_mac_addr}" = "xtrue" ] && [ -f /etc/cpsw_4_mac ] ; then
		mac_addr4=$(cat /etc/cpsw_4_mac)
	else
		if [ -f /usr/bin/bc ] ; then
			#bc cuts off leading zero's, we need ten/ones value
			new_octet_6=$(echo "obase=16;ibase=16;$cpsw_0_6 + 105" | bc)

			mac_addr4=${mac_addr0_octet_1_5}:$(echo ${new_octet_6} | cut -c 2-3)
		else
			mac_addr4="1C:BA:8C:A2:ED:72"
		fi
		echo "${mac_addr4}" > /etc/cpsw_4_mac || true
	fi

	if [ "x${use_cached_mac_addr}" = "xtrue" ] && [ -f /etc/cpsw_5_mac ] ; then
		mac_addr5=$(cat /etc/cpsw_5_mac)
	else
		if [ -f /usr/bin/bc ] ; then
			#bc cuts off leading zero's, we need ten/ones value
			new_octet_6=$(echo "obase=16;ibase=16;$cpsw_0_6 + 106" | bc)

			mac_addr5=${mac_addr0_octet_1_5}:$(echo ${new_octet_6} | cut -c 2-3)
		else
			mac_addr5="1C:BA:8C:A2:ED:73"
		fi
		echo "${mac_addr5}" > /etc/cpsw_5_mac || true
	fi

	echo "${log} cpsw_0_mac: [${mac_addr0}]"
	echo "${log} cpsw_1_mac: [${mac_addr1}]"
	echo "${log} cpsw_2_mac: [${mac_addr2}]"
	echo "${log} cpsw_3_mac: [${mac_addr3}]"
	echo "${log} cpsw_4_mac: [${mac_addr4}]"
	echo "${log} cpsw_5_mac: [${mac_addr5}]"
fi

#udhcpd gets started at bootup, but we need to wait till g_multi is loaded, and we run it manually...
if [ -f /var/run/udhcpd.pid ] ; then
	echo "${log} [/etc/init.d/udhcpd stop]"
	/etc/init.d/udhcpd stop || true
fi

if [ ! -f /etc/systemd/system/getty.target.wants/serial-getty@ttyGS0.service ] ; then
	ln -s /lib/systemd/system/serial-getty@.service /etc/systemd/system/getty.target.wants/serial-getty@ttyGS0.service
fi

run_libcomposite_start () {
	echo ${usb_bcdUSB} > bcdUSB
	echo ${usb_idVendor} > idVendor # Linux Foundation
	echo ${usb_idProduct} > idProduct # Multifunction Composite Gadget
	echo ${usb_bcdDevice} > bcdDevice

	#0x409 = english strings...
	mkdir -p strings/0x409

	echo ${usb_iserialnumber} > strings/0x409/serialnumber
	echo ${usb_imanufacturer} > strings/0x409/manufacturer
	echo ${usb_iproduct} > strings/0x409/product

	#echo 0xEF > bDeviceClass
	#echo 0x02 > bDeviceSubClass
	#echo 0x01 > bDeviceProtocol

	mkdir -p configs/c.1/strings/0x409
	echo "BeagleBone Composite" > configs/c.1/strings/0x409/configuration

	echo 500 > configs/c.1/MaxPower

	if [ ! "x${USB_NETWORK_DISABLED}" = "xyes" ]; then
		mkdir -p functions/rndis.usb0
		# first byte of address must be even
		echo ${cpsw_1_mac} > functions/rndis.usb0/host_addr
		echo ${cpsw_2_mac} > functions/rndis.usb0/dev_addr

		#jason had this disabled...
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

		mkdir -p configs/c.1
		ln -s configs/c.1 os_desc
		mkdir functions/rndis.usb0/os_desc/interface.rndis/Icons
		echo 2 > functions/rndis.usb0/os_desc/interface.rndis/Icons/type
		echo "%SystemRoot%\\system32\\shell32.dll,-233" > functions/rndis.usb0/os_desc/interface.rndis/Icons/data
		mkdir functions/rndis.usb0/os_desc/interface.rndis/Label
		echo 1 > functions/rndis.usb0/os_desc/interface.rndis/Label/type
		echo "BeagleBone USB Ethernet" > functions/rndis.usb0/os_desc/interface.rndis/Label/data

	#if [ ! "x${USB_NETWORK_DISABLED}" = "xyes" ]; then
		ln -s functions/rndis.usb0 configs/c.1/
	#fi

	fi

	if [ "x${has_img_file}" = "xtrue" ] ; then
		echo "${log} enable USB mass_storage ${usb_image_file}"
		mkdir -p functions/mass_storage.usb0
		echo ${usb_ms_stall} > functions/mass_storage.usb0/stall
		echo ${usb_ms_cdrom} > functions/mass_storage.usb0/lun.0/cdrom
		echo ${usb_ms_nofua} > functions/mass_storage.usb0/lun.0/nofua
		echo ${usb_ms_removable} > functions/mass_storage.usb0/lun.0/removable
		echo ${usb_ms_ro} > functions/mass_storage.usb0/lun.0/ro
		echo ${usb_image_file} > functions/mass_storage.usb0/lun.0/file

	#if [ "x${has_img_file}" = "xtrue" ] ; then
		ln -s functions/mass_storage.usb0 configs/c.1/
	#fi

	fi

	if [ ! "x${USB_NETWORK_DISABLED}" = "xyes" ]; then
		mkdir -p functions/ncm.usb0
		echo ${cpsw_3_mac} > functions/ncm.usb0/host_addr
		echo ${cpsw_4_mac} > functions/ncm.usb0/dev_addr

	#if [ ! "x${USB_NETWORK_DISABLED}" = "xyes" ]; then
		ln -s functions/ncm.usb0 configs/c.1/
	#fi

	fi

	if [ "x${usb_serial_gadget}" = "xenable" ] ; then
		mkdir -p functions/acm.usb0
		ln -s functions/acm.usb0 configs/c.1/
	fi

	#ls /sys/class/udc
	echo 48890000.usb > UDC
	echo "${log} g_multi Created"
}

run_libcomposite_jdk () {
	if [ ! -d /sys/kernel/config/usb_gadget/g_multi/ ] ; then
		echo "${log} Creating g_multi"
		mkdir -p /sys/kernel/config/usb_gadget/g_multi || true
		cd /sys/kernel/config/usb_gadget/g_multi

		usb_bcdUSB="0x0300"

		run_libcomposite_start
	fi
}

run_libcomposite () {
	if [ ! -d /sys/kernel/config/usb_gadget/g_multi/ ] ; then
		echo "${log} Creating g_multi"
		mkdir -p /sys/kernel/config/usb_gadget/g_multi || true
		cd /sys/kernel/config/usb_gadget/g_multi

		run_libcomposite_start

	else
		echo "${log} FIXME: need to bring down g_multi first, before running a second time."
	fi
}

use_libcomposite () {
	echo "${log} use_libcomposite"

	until [ -d /sys/class/udc/48890000.usb/ ] ; do
		sleep 3
		echo "usb_gadget: waiting for /sys/class/udc/48890000.usb/"
	done

	echo "${log} Looking for libcomposite"
	if [ -d /sys/kernel/config/usb_gadget/ ] ; then
		run_libcomposite
	else
		echo "${log} modprobe libcomposite"
		modprobe libcomposite || true
		if [ -d /sys/module/libcomposite ] ; then
			#run_libcomposite
			run_libcomposite_jdk
			#/bin/bash /opt/scripts/boot/bbai_usb_gadget.sh
		else
			if [ -f /sbin/depmod ] ; then
				/sbin/depmod -a
			fi
			echo "${log} ERROR: [libcomposite didn't load]"
		fi
	fi
}

use_libcomposite

if [ -f /var/lib/misc/dnsmasq.leases ] ; then
	systemctl stop dnsmasq || true
	rm -rf /var/lib/misc/dnsmasq.leases || true
fi

		echo "${log} Starting usb0 network"
		# Auto-configuring the usb0 network interface:
		if [ -f /usr/bin/autoconfigure_usb0.sh ] ; then
			/usr/bin/autoconfigure_usb0.sh || true
		else
			#Old Path... 2020.02.25
			$(dirname $0)/autoconfigure_usb0.sh || true
		fi

		echo "${log} Starting usb1 network"
		# Auto-configuring the usb1 network interface:
		if [ -f /usr/bin/autoconfigure_usb1.sh ] ; then
			/usr/bin/autoconfigure_usb1.sh || true
		else
			#Old Path... 2020.02.25
			$(dirname $0)/autoconfigure_usb1.sh || true
		fi

		if [ -d /sys/kernel/config/usb_gadget ] ; then
			if [ -f /var/run/udhcpd.pid ] ; then
				/etc/init.d/udhcpd stop || true
			fi

			# do not write if there is a .SoftAp0 file
			if [ -d /etc/dnsmasq.d/ ] ; then
				if [ ! -f /etc/dnsmasq.d/.SoftAp0 ] ; then
					echo "${log} dnsmasq: setting up for usb0/usb1"
					disable_connman_dnsproxy

					if [ -f /usr/bin/bb_dnsmasq_config.sh ] ; then
						/usr/bin/bb_dnsmasq_config.sh || true
					else
						wfile="/etc/dnsmasq.d/SoftAp0"
						echo "interface=usb0" > ${wfile}

						if [ "x${USB1_ENABLE}" = "xenable" ] ; then
							echo "interface=usb1" >> ${wfile}
						fi

						echo "port=53" >> ${wfile}
						echo "dhcp-authoritative" >> ${wfile}
						echo "domain-needed" >> ${wfile}
						echo "bogus-priv" >> ${wfile}
						echo "expand-hosts" >> ${wfile}
						echo "cache-size=2048" >> ${wfile}
						echo "dhcp-range=usb0,${USB0_SUBNET}.1,${USB0_SUBNET}.1,2m" >> ${wfile}

						if [ "x${USB1_ENABLE}" = "xenable" ] ; then
							echo "dhcp-range=usb1,${USB1_SUBNET}.1,${USB1_SUBNET}.1,2m" >> ${wfile}
						fi

						echo "listen-address=127.0.0.1" >> ${wfile}
						echo "listen-address=${USB0_ADDRESS}" >> ${wfile}

						if [ "x${USB1_ENABLE}" = "xenable" ] ; then
							echo "listen-address=${USB1_ADDRESS}" >> ${wfile}
						fi

						echo "dhcp-option=usb0,3" >> ${wfile}
						echo "dhcp-option=usb0,6" >> ${wfile}

						if [ "x${USB1_ENABLE}" = "xenable" ] ; then
							echo "dhcp-option=usb1,3" >> ${wfile}
							echo "dhcp-option=usb1,6" >> ${wfile}
						fi

						echo "dhcp-leasefile=/var/run/dnsmasq.leases" >> ${wfile}
					fi

					systemctl restart dnsmasq || true
				else
					echo "${log} LOG: dnsmasq is disabled in this script"
				fi
			else
				echo "${log} ERROR: dnsmasq is not installed"
			fi
		fi

check_getty_tty=$(systemctl is-active serial-getty@ttyGS0.service || true)
if [ "x${check_getty_tty}" = "xinactive" ] ; then
	systemctl restart serial-getty@ttyGS0.service || true
fi

#if [ -f /usr/bin/cpufreq-set ] ; then
#	echo "${log} cpufreq-set -g powersave"
#	/usr/bin/cpufreq-set -g powersave || true
#fi

echo wlan0 > /sys/class/leds/beaglebone\:green\:usr4/device_name
echo 1 > /sys/class/leds/beaglebone\:green\:usr4/link
echo 1 > /sys/class/leds/beaglebone\:green\:usr4/rx
echo 1 > /sys/class/leds/beaglebone\:green\:usr4/tx

if [ -f /etc/systemd/system/multi-user.target.wants/robotcontrol.service ] ; then
	echo "${log} systemctl: disable robotcontrol.service"
	systemctl disable robotcontrol.service || true
	rm -f /etc/modules-load.d/robotcontrol_modules.conf || true
fi
if [ -f /etc/systemd/system/multi-user.target.wants/rc_battery_monitor.service ] ; then
	echo "${log} systemctl: rc_battery_monitor.service"
	systemctl disable rc_battery_monitor.service || true
fi

#
