#!/bin/bash -e

eeprom_location=$(ls /sys/devices/ocp.*/44e0b000.i2c/i2c-0/0-0050/eeprom 2> /dev/null)
if [ ! "x${eeprom_location}" = "x" ] ; then
	echo "Blanking EEPROM"
	sudo dd if=/dev/zero of=${eeprom_location}
fi

eeprom="/sys/bus/i2c/devices/0-0050/eeprom"

eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -s 5 -n 3)
if [ "x${eeprom_header}" = "x335" ] ; then
	echo "EEPROM: blanking failed"
else
	echo "EEPROM: blanked"
fi

sudo dd if=/dev/zero of=/dev/mmcblk1 bs=1M count=16
sudo touch /boot/uboot/flash-eMMC.txt
