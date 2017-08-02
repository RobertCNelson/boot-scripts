#!/bin/bash -e

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

dump () {
	echo "checking: ${pre}${address}/${post}"
	if [ -f ${pre}${address}/${post} ] ; then
		cape_header=$(hexdump -C ${pre}${address}/${post} -n 32)
		echo "cape: [${cape_header}]"
	fi
}

eeprom_dump () {
	address="0054" ; dump
	address="0055" ; dump
	address="0056" ; dump
	address="0057" ; dump
}

nvmem_dump () {
	address="at24-1" ; dump
	address="at24-2" ; dump
	address="at24-3" ; dump
	address="at24-4" ; dump
}

if [ -f /sys/bus/i2c/devices/1-0054/eeprom ] ; then
	pre="/sys/bus/i2c/devices/1-"
	post="eeprom"
	eeprom_dump
fi

if [ -f /sys/bus/i2c/devices/2-0054/eeprom ] ; then
	pre="/sys/bus/i2c/devices/2-"
	post="eeprom"
	eeprom_dump
fi

if [ -f /sys/bus/nvmem/devices/at24-1/nvmem ] ; then
	pre="/sys/bus/nvmem/devices/"
	post="nvmem"
	nvmem_dump
fi
