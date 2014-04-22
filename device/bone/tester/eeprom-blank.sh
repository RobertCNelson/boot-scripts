#!/bin/bash -e

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

eeprom="/sys/bus/i2c/devices/0-0050/eeprom"
eeprom_location=$(ls /sys/devices/ocp.*/44e0b000.i2c/i2c-0/0-0050/eeprom 2> /dev/null)
eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -s 5 -n 3)
if [ "x${eeprom_header}" = "x335" ] ; then
	if [ ! "x${eeprom_location}" = "x" ] ; then
		echo "Blanking EEPROM"
		dd if=/dev/zero of=${eeprom_location} bs=1K count=1
	fi
fi

eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -s 5 -n 3)
if [ "x${eeprom_header}" = "x335" ] ; then
	echo "EEPROM: blanking failed"
else
	echo "EEPROM: blanked"
fi

sed -i -e 's:CAPE:CAPE=BB-BONE-eMMC1-01:g' /etc/default/capemgr

dd if=/dev/zero of=/dev/mmcblk1 bs=1M count=16
touch /boot/uboot/flash-eMMC.txt
