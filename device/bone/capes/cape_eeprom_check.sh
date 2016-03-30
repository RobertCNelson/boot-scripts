#!/bin/bash -e

dump () {
	echo "trying: ${pre}${address}/${post}"
	cat ${pre}${address}/${post} | hexdump -C
}

eeprom_dump () {
	address="0054" ; dump
	address="0055" ; dump
	address="0056" ; dump
	address="0057" ; dump
}

if [ -f /sys/bus/i2c/devices/1-0054/eeprom ] ; then
	pre="/sys/bus/i2c/devices/1-"
	post="eeprom"
	eeprom_dump
fi

if [ -f /sys/bus/i2c/devices/2-0054/at24-1/nvmem ] ; then
	pre="/sys/bus/i2c/devices/2-"
	post="at24-1/nvmem"
	eeprom_dump
fi
