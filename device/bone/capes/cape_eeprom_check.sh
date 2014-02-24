#!/bin/sh

echo "trying: /sys/bus/i2c/devices/1-0054/eeprom"
cat /sys/bus/i2c/devices/1-0054/eeprom | hexdump -C

echo "trying: /sys/bus/i2c/devices/1-0055/eeprom"
cat /sys/bus/i2c/devices/1-0055/eeprom | hexdump -C

echo "trying: /sys/bus/i2c/devices/1-0056/eeprom"
cat /sys/bus/i2c/devices/1-0056/eeprom | hexdump -C

echo "trying: /sys/bus/i2c/devices/1-0057/eeprom"
cat /sys/bus/i2c/devices/1-0057/eeprom | hexdump -C

echo "cat eeprom.dump > /sys/bus/i2c/devices/1-005X/eeprom"
