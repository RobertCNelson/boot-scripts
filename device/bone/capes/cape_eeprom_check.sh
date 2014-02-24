#!/bin/sh

cat /sys/bus/i2c/devices/1-0054/eeprom | hexdump -c
cat /sys/bus/i2c/devices/1-0055/eeprom | hexdump -c
cat /sys/bus/i2c/devices/1-0056/eeprom | hexdump -c
cat /sys/bus/i2c/devices/1-0057/eeprom | hexdump -c

