#!/bin/bash -e
#
# Copyright (c) 2013-2016 Robert Nelson <robertcnelson@gmail.com>
# Portions copyright (c) 2014 Charles Steinkuehler <charles@steinkuehler.net>
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

version_message="1.20160222: deal with v4.4.x+ back to old eeprom location..."

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

broadcast () {
	if [ "x${message}" != "x" ] ; then
		echo "${message}"
		echo "${message}" > /dev/tty0 || true
	fi
}

check_eeprom () {
	device_eeprom="bp00-eeprom"
	message="Checking for Valid ${device_eeprom} header" ; broadcast

	unset got_eeprom
	#v8 of nvmem...
	if [ -f /sys/bus/nvmem/devices/at24-0/nvmem ] && [ "x${got_eeprom}" = "x" ] ; then
		eeprom="/sys/bus/nvmem/devices/at24-0/nvmem"
		eeprom_location="/sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/at24-0/nvmem"
		got_eeprom="true"
	fi

	#pre-v8 of nvmem...
	if [ -f /sys/class/nvmem/at24-0/nvmem ] && [ "x${got_eeprom}" = "x" ] ; then
		eeprom="/sys/class/nvmem/at24-0/nvmem"
		eeprom_location="/sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/nvmem/at24-0/nvmem"
		got_eeprom="true"
	fi

	#eeprom 3.8.x & 4.4 with eeprom-nvmem patchset...
	if [ -f /sys/bus/i2c/devices/0-0050/eeprom ] && [ "x${got_eeprom}" = "x" ] ; then
		eeprom="/sys/bus/i2c/devices/0-0050/eeprom"

		if [ -f /sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/eeprom ] ; then
			eeprom_location="/sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/eeprom"
		else
			eeprom_location=$(ls /sys/devices/ocp*/44e0b000.i2c/i2c-0/0-0050/eeprom 2> /dev/null)
		fi

		got_eeprom="true"
	fi

		if [ "x${got_eeprom}" = "xtrue" ] ; then
			eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -n 8 | cut -b 6-8)
			if [ "x${eeprom_header}" = "x335" ] ; then
				message="Valid ${device_eeprom} header found [${eeprom_header}]" ; broadcast
				message="-----------------------------" ; broadcast
			else
				message="Invalid EEPROM header detected" ; broadcast
				if [ -f /opt/scripts/device/bone/${device_eeprom}.dump ] ; then
					if [ ! "x${eeprom_location}" = "x" ] ; then
						message="Writing header to EEPROM" ; broadcast
						dd if=/opt/scripts/device/bone/${device_eeprom}.dump of=${eeprom_location}
						sync
						sync
						eeprom_check=$(hexdump -e '8/1 "%c"' ${eeprom} -n 8 | cut -b 6-8)
						echo "eeprom check: [${eeprom_check}]"

						#We have to reboot, as the kernel only loads the eMMC cape
						# with a valid header
						reboot -f

						#We shouldnt hit this...
						exit
					fi
				else
					message="error: no [/opt/scripts/device/bone/${device_eeprom}.dump]" ; broadcast
				fi
			fi
		fi
}

sleep 1
clear
message="-----------------------------" ; broadcast
message="Starting eeprom Flasher from microSD media" ; broadcast
message="Version: [${version_message}]" ; broadcast
message="-----------------------------" ; broadcast

check_eeprom

#To properly shudown, /opt/scripts/boot/am335x_evm.sh is going to call halt:
exec /sbin/init
#
