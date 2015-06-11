#!/bin/sh -e
#
# Copyright (c) 2014-2015 Robert Nelson <robertcnelson@gmail.com>
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

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

DRIVE="/boot/uboot"

TEMPDIR=$(mktemp -d)

dl_bootloader () {
	echo ""
	echo "Downloading Device's Bootloader"
	echo "-----------------------------"
	conf_bl_http="http://rcn-ee.com/repos/bootloader/latest"
	conf_bl_listfile="bootloader-ng"
	minimal_boot="1"

	mkdir -p ${TEMPDIR}/dl/${DISTARCH}

	wget --no-verbose --directory-prefix="${TEMPDIR}/dl/" ${conf_bl_http}/${conf_bl_listfile}

	if [ ! -f ${TEMPDIR}/dl/${conf_bl_listfile} ] ; then
		echo "error: can't connect to rcn-ee.com, retry in a few minutes..."
		exit
	fi

	boot_version=$(cat ${TEMPDIR}/dl/${conf_bl_listfile} | grep "VERSION:" | awk -F":" '{print $2}')
	if [ "x${boot_version}" != "x${minimal_boot}" ] ; then
		echo "Error: This script is out of date and unsupported..."
		echo "Please Visit: https://github.com/RobertCNelson to find updates..."
		exit
	fi

	if [ "${USE_BETA_BOOTLOADER}" ] ; then
		ABI="ABX2"
	else
		ABI="ABI2"
	fi

	if [ "${spl_name}" ] ; then
		SPL=$(cat ${TEMPDIR}/dl/${conf_bl_listfile} | grep "${ABI}:${conf_board}:SPL" | awk '{print $2}')
		wget --no-verbose --directory-prefix="${TEMPDIR}/dl/" ${SPL}
		SPL=${SPL##*/}
		echo "SPL Bootloader: ${SPL}"
	else
		unset SPL
	fi

	if [ "${boot_name}" ] ; then
		UBOOT=$(cat ${TEMPDIR}/dl/${conf_bl_listfile} | grep "${ABI}:${conf_board}:BOOT" | awk '{print $2}')
		wget --directory-prefix="${TEMPDIR}/dl/" ${UBOOT}
		UBOOT=${UBOOT##*/}
		echo "UBOOT Bootloader: ${UBOOT}"
	else
		unset UBOOT
	fi
}

is_imx () {
	unset spl_name
	boot_name="u-boot.imx"
}

is_omap () {
	spl_name="MLO"
	boot_name="u-boot.img"
}

fatfs_boot () {
	echo "-----------------------------"
	echo "Warning: this script will flash your bootloader with:"
	echo "SPL: [${SPL}]"
	echo "u-boot.img: [${UBOOT}]"
	echo "for: [${conf_board}]"
	echo ""
	echo -n "Are you 100% sure, on selecting [${conf_board}] (y/n)? "
	read response
	if [ "x${response}" = "xy" ] ; then
		echo "-----------------------------"
		if [ "${spl_name}" ] ; then
			if [ -f ${TEMPDIR}/dl/${SPL} ] ; then
				rm -f ${DRIVE}/${spl_name} || true
				cp -v ${TEMPDIR}/dl/${SPL} ${DRIVE}/${spl_name}
				sync
			fi
		fi

		if [ "${boot_name}" ] ; then
			if [ -f ${TEMPDIR}/dl/${UBOOT} ] ; then
				rm -f ${DRIVE}/${boot_name} || true
				cp -v ${TEMPDIR}/dl/${UBOOT} ${DRIVE}/${boot_name}
				sync
			fi
		fi
		echo "-----------------------------"
		echo "Bootloader Updated"
	fi
}

dd_uboot_boot () {
	echo "-----------------------------"
	echo "Warning: this script will flash your bootloader with:"
	echo "u-boot.imx: [${UBOOT}]"
	echo "for: [${conf_board}]"
	echo ""
	echo -n "Are you 100% sure, on selecting [${conf_board}] (y/n)? "
	read response
	if [ "x${response}" = "xy" ] ; then
		echo "-----------------------------"

		if [ "x${dd_seek}" != "x" ] ; then
			dd_uboot_seek=${dd_seek}
		fi

		if [ "x${dd_bs}" != "x" ] ; then
			dd_uboot_bs=${dd_bs}
		fi

		if [ "x${dd_uboot_seek}" = "x" ] ; then
			echo "dd_seek/dd_uboot_seek not found in ${DRIVE}/SOC.sh halting"
			echo "-----------------------------"
			exit
		fi

		if [ "x${dd_uboot_bs}" = "x" ] ; then
			echo "dd_bs/dd_uboot_bs not found in ${DRIVE}/SOC.sh halting"
			echo "-----------------------------"
			exit
		fi

		if [ -f ${TEMPDIR}/dl/${UBOOT} ] ; then
			echo "dd if=${TEMPDIR}/dl/${UBOOT} of=${target} seek=${dd_uboot_seek} bs=${dd_uboot_bs}"
			sudo dd if=${TEMPDIR}/dl/${UBOOT} of=${target} seek=${dd_uboot_seek} bs=${dd_uboot_bs}
			sync
			flashed=done
		fi
		echo "-----------------------------"
		echo "Bootloader Updated"
	fi
}

dd_spl_uboot_boot () {
	echo "-----------------------------"
	echo "Warning: this script will flash your bootloader with:"
	echo "u-boot-mmc-spl.bin: [${SPL}]"
	echo "u-boot.bin: [${UBOOT}]"
	echo "for: [${conf_board}]"
	echo ""
	echo -n "Are you 100% sure, on selecting [${conf_board}] (y/n)? "
	read response
	if [ "x${response}" = "xy" ] ; then
		echo "-----------------------------"

		if [ "x${dd_spl_uboot_seek}" = "x" ] ; then
			echo "dd_spl_uboot_seek not found in ${DRIVE}/SOC.sh halting"
			echo "-----------------------------"
			exit
		fi

		if [ "x${dd_spl_uboot_bs}" = "x" ] ; then
			echo "dd_spl_uboot_bs not found in ${DRIVE}/SOC.sh halting"
			echo "-----------------------------"
			exit
		fi

		if [ "x${dd_uboot_seek}" = "x" ] ; then
			echo "dd_uboot_seek not found in ${DRIVE}/SOC.sh halting"
			echo "-----------------------------"
			exit
		fi

		if [ "x${dd_uboot_bs}" = "x" ] ; then
			echo "dd_uboot_bs not found in ${DRIVE}/SOC.sh halting"
			echo "-----------------------------"
			exit
		fi

		if [ -f ${TEMPDIR}/dl/${UBOOT} ] ; then
			echo "log: dd if=${TEMPDIR}/dl/${SPL} of=${target} seek=${dd_spl_uboot_seek} bs=${dd_spl_uboot_bs}"
			sudo dd if=${TEMPDIR}/dl/${SPL} of=${target} seek=${dd_spl_uboot_seek} bs=${dd_spl_uboot_bs}
			echo "log: dd if=${TEMPDIR}/dl/${UBOOT} of=${target} seek=${dd_uboot_seek} bs=${dd_uboot_bs}"
			sudo dd if=${TEMPDIR}/dl/${UBOOT} of=${target} seek=${dd_uboot_seek} bs=${dd_uboot_bs}
			sync
			flashed=done
		fi
		echo "-----------------------------"
		echo "Bootloader Updated"
	fi
}

got_board () {
	target="/dev/mmcblk0"
	case "${conf_board}" in
	am335x_evm|beagle_x15)
		is_omap
		;;
	omap5_uevm)
		target="/dev/mmcblk1"
		is_omap
		;;
	esac

	case "${bootloader_location}" in
	omap_fatfs_boot_part|fatfs_boot)
		is_omap
		dl_bootloader
		fatfs_boot
		;;
	dd_to_drive|dd_uboot_boot)
		is_imx
		dl_bootloader
		dd_uboot_boot
		;;
	dd_spl_uboot_boot)
		dl_bootloader
		dd_spl_uboot_boot
		;;
	esac
}

check_soc_sh () {
	echo "Bootloader Recovery"
	if [ ! "x$(uname -m)" = "xarmv7l" ] ; then
		echo "Warning, this is only half implemented to make it work on x86..."
		echo "mount your mmc drive to /tmp/uboot/"
		DRIVE="/tmp/uboot"
	fi

	if [ -f ${DRIVE}/SOC.sh ] ; then
		. ${DRIVE}/SOC.sh
		if [ "x${board}" != "x" ] ; then

			if [ "x${board}" = "xam335x_boneblack" ] ; then
				#Special eeprom less u-boot, switch them to normal on upgrades
				sed -i -e 's:am335x_boneblack:am335x_evm:g' ${DRIVE}/SOC.sh
				board="am335x_evm"
			fi

			conf_board="${board}"
			got_board
		else
			echo "Sorry: board undefined in [${DRIVE}/SOC.sh] can not update bootloader safely"
			exit
		fi
	fi

	if [ "x${flashed}" = "x" ] ; then
		if [ -f /boot/SOC.sh ] ; then
			. /boot/SOC.sh
			mkdir -p /tmp/uboot/
			mount /dev/mmcblk0p1 /tmp/uboot/
			DRIVE="/tmp/uboot"
			if [ "x${board}" != "x" ] ; then

				if [ "x${board}" = "xam335x_boneblack" ] ; then
					#Special eeprom less u-boot, switch them to normal on upgrades
					sed -i -e 's:am335x_boneblack:am335x_evm:g' ${DRIVE}/SOC.sh
					board="am335x_evm"
				fi

				conf_board="${board}"
				got_board
			else
				echo "Sorry: board undefined in [${DRIVE}/SOC.sh] can not update bootloader safely"
				exit
			fi
			sync
			sync
			umount /tmp/uboot/ || true
		fi
	fi

	if [ "x${flashed}" = "x" ] ; then
		if [ -f /boot/uboot/SOC.sh ] ; then
			. /boot/uboot/SOC.sh
			mkdir -p /tmp/uboot/
			mount /dev/mmcblk0p1 /tmp/uboot/
			DRIVE="/tmp/uboot"
			if [ "x${board}" != "x" ] ; then

				if [ "x${board}" = "xam335x_boneblack" ] ; then
					#Special eeprom less u-boot, switch them to normal on upgrades
					sed -i -e 's:am335x_boneblack:am335x_evm:g' ${DRIVE}/SOC.sh
					board="am335x_evm"
				fi

				conf_board="${board}"
				got_board
			else
				echo "Sorry: board undefined in [${DRIVE}/SOC.sh] can not update bootloader safely"
				exit
			fi
			sync
			sync
			umount /tmp/uboot/ || true
		fi
	fi

	if [ $(uname -m) != "armv7l" ] ; then
		sync
		sync
		sudo umount ${DRIVE}/ || true
	fi
	echo "Bootloader Recovery Complete"
}

unset flashed
# parse commandline options
while [ ! -z "$1" ] ; do
	case $1 in
	--use-beta-bootloader)
		USE_BETA_BOOTLOADER=1
		;;
	esac
	shift
done

check_soc_sh

