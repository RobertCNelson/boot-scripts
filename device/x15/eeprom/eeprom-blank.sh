#!/bin/bash -e

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

unset got_eeprom

#eeprom...
if [ -f /sys/bus/i2c/devices/0-0050/eeprom ] && [ "x${got_eeprom}" = "x" ] ; then
	eeprom="/sys/bus/i2c/devices/0-0050/eeprom"
	if [ -f /sys/devices/platform/44000000.ocp/48070000.i2c/i2c-0/0-0050/eeprom ] ; then
		eeprom_location="/sys/devices/platform/44000000.ocp/48070000.i2c/i2c-0/0-0050/eeprom"
		got_eeprom="true"
	fi
fi

if [ "x${got_eeprom}" = "xtrue" ] ; then
	echo "dd if=/dev/zero of=${eeprom_location}"
	dd if=/dev/zero of=${eeprom_location}
	echo "done, syncing..."
	sync
	sync
	eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -n 16)
	eeprom_raw_rev=$(hexdump -C ${eeprom} -n 16 | grep 00000000)
	eeprom_raw_serial_10=$(hexdump -C ${eeprom} -n 32 | grep 00000010)
	eeprom_raw_serial_20=$(hexdump -C ${eeprom} -n 48 | grep 00000020)
	echo "eeprom: [${eeprom_header}]"
	echo "eeprom raw: [${eeprom_raw_rev}]"
	echo "eeprom raw: [${eeprom_raw_serial_10}]"
	echo "eeprom raw: [${eeprom_raw_serial_20}]"
fi
