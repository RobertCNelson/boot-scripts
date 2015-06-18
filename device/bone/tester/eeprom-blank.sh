#!/bin/bash -e

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

if [ -f /sys/class/nvmem/at24-0/nvmem ] ; then
	eeprom="/sys/class/nvmem/at24-0/nvmem"

	#with 4.1.x: -s 5 isn't working...
	#eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -s 5 -n 3) = blank...
	#hexdump -e '8/1 "%c"' ${eeprom} -n 8 = �U3�A335
	eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -n 8 | cut -b 6-8)

	eeprom_location="/sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/nvmem/at24-0/nvmem"
else
	eeprom="/sys/bus/i2c/devices/0-0050/eeprom"
	eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -s 5 -n 3)
	eeprom_location=$(ls /sys/devices/ocp*/44e0b000.i2c/i2c-0/0-0050/eeprom 2> /dev/null)
fi

if [ "x${eeprom_header}" = "x335" ] ; then
	if [ ! "x${eeprom_location}" = "x" ] ; then
		echo "Blanking EEPROM"
		dd if=/dev/zero of=${eeprom_location} bs=1K count=1
	fi
fi

eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -n 8 | cut -b 6-8)
if [ "x${eeprom_header}" = "x335" ] ; then
	echo "EEPROM: blanking failed"
else
	echo "EEPROM: blanked"
fi
