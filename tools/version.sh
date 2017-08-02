#!/bin/sh -e
#

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

git_bin=$(which git)

omap_bootloader () {
	unset test_var
	test_var=$(dd if=${drive} count=6 skip=393248 bs=1 2>/dev/null || true)
	if [ "x${test_var}" = "xU-Boot" ] ; then
		uboot=$(dd if=${drive} count=32 skip=393248 bs=1 2>/dev/null || true)
		uboot=$(echo ${uboot} | awk '{print $2}')
		echo "bootloader:[${label}]:[${drive}]:[U-Boot ${uboot}]"
	else
		if [ -f /boot/uboot/u-boot.img ] ; then
			if [ -f /usr/bin/mkimage ] ; then
				unset uboot
				uboot=$(/usr/bin/mkimage -l /boot/uboot/u-boot.img | grep Description | head -n1 | awk '{print $3}' 2>/dev/null || true)
				if [ ! "x${uboot}" = "x" ] ; then
					echo "bootloader:[${label}]:[${drive}]:[U-Boot ${uboot}]"
				else
					unset uboot
					uboot=$(/usr/bin/mkimage -l /boot/uboot/u-boot.img | grep Name:| head -n1 | awk '{print $4}' 2>/dev/null || true)
					if [ ! "x${uboot}" = "x" ] ; then
						echo "bootloader:[${label}]:[${drive}]:[U-Boot ${uboot}]"
					fi
				fi
			fi
		fi
	fi
}

dpkg_check_version () {
	unset pkg_version
	pkg_version=$(dpkg -l | awk '$2=="'$pkg'" { print $3 }' || true)
	if [ ! "x${pkg_version}" = "x" ] ; then
		echo "pkg:[$pkg]:[$pkg_version]"
	else
		echo "WARNING:pkg:[$pkg]:[NOT_INSTALLED]"
	fi
}

if [ -f ${git_bin} ] ; then
	if [ -d /opt/scripts/ ] ; then
		old_dir="`pwd`"
		cd /opt/scripts/ || true
		echo "git:/opt/scripts/:[`${git_bin} rev-parse HEAD`]"
		cd "${old_dir}" || true
	fi
fi

if [ -f /sys/bus/i2c/devices/0-0050/eeprom ] ; then
	board_eeprom=$(hexdump -e '8/1 "%c"' /sys/bus/i2c/devices/0-0050/eeprom -n 28 | cut -b 5-28 || true)
	echo "eeprom:[${board_eeprom}]"
fi

if [ -f /etc/dogtag ] ; then
	echo "dogtag:[`cat /etc/dogtag`]"
fi

#if [ -f /bin/lsblk ] ; then
#	lsblk | sed 's/^/partition_table:[/' | sed 's/$/]/'
#fi

machine=$(cat /proc/device-tree/model | sed "s/ /_/g" | tr -d '\000')

if [ "x${SOC}" = "x" ] ; then
	case "${machine}" in
	TI_AM5728_Beagle*)
		mmc0_label="microSD-(primary)"
		mmc1_label="eMMC-(secondary)"
		;;
	TI_OMAP5_uEVM_board)
		mmc0_label="eMMC-(secondary)"
		mmc1_label="microSD-(primary)"
		;;
	*)
		mmc0_label="microSD-(push-button)"
		mmc1_label="eMMC-(default)"
		;;
	esac
fi

if [ -b /dev/mmcblk0 ] ; then
	label=${mmc0_label}
	drive=/dev/mmcblk0
	omap_bootloader
fi

if [ -b /dev/mmcblk1 ] ; then
	label=${mmc1_label}
	drive=/dev/mmcblk1
	omap_bootloader
fi

echo "kernel:[`uname -r`]"

if [ -f /usr/bin/nodejs ] ; then
	echo "nodejs:[`/usr/bin/nodejs --version`]"
fi

if [ -f /boot/uEnv.txt ] ; then
	unset test_var
	test_var=$(cat /boot/uEnv.txt | grep -v '#' | grep dtb | grep -v dtbo || true)
	if [ "x${test_var}" != "x" ] ; then
		echo "device-tree-override:[$test_var]"
	fi
fi

if [ -f /boot/uEnv.txt ] ; then
	unset test_var
	test_var=$(cat /boot/uEnv.txt | grep -v '#' | grep enable_uboot_overlays=1 || true)
	if [ "x${test_var}" != "x" ] ; then
		cat /boot/uEnv.txt | grep uboot_ | grep -v '#' | sed 's/^/uboot_overlay_options:[/' | sed 's/$/]/'
	fi
fi

pkg="bb-cape-overlays" ; dpkg_check_version
pkg="bb-wl18xx-firmware" ; dpkg_check_version
pkg="firmware-ti-connectivity" ; dpkg_check_version
#
