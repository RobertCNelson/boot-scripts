#!/bin/bash -e

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

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

#eeprom...
if [ -f /sys/bus/i2c/devices/0-0050/eeprom ] && [ "x${got_eeprom}" = "x" ] ; then
	eeprom="/sys/bus/i2c/devices/0-0050/eeprom"
	eeprom_location=$(ls /sys/devices/ocp*/44e0b000.i2c/i2c-0/0-0050/eeprom 2> /dev/null)
	got_eeprom="true"
fi

if [ "x${got_eeprom}" = "xtrue" ] ; then
	dd if=/dev/zero of=${eeprom_location}
	sync
	sync
	eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -n 16)
	eeprom_raw=$(hexdump ${eeprom} -n 16 | grep -v 0000008)
	echo "eeprom: [${eeprom_header}]"
	echo "eeprom raw: [${eeprom_raw}]"
fi
