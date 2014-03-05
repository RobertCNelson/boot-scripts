#!/bin/sh

if [ -f /etc/Wireless/RT2870/RT2870STA.dat ] ; then
	#fixed: https://github.com/rcn-ee/farm/commit/f5e66c19decc06954f00509913a4a2cdf1afd7bc
	echo "MT601: Moving RT2870STA.dat to /etc/Wireless/RT2870STA/RT2870STA.dat"
	sudo mkdir -p /etc/Wireless/RT2870STA/ || true
	sudo mv /etc/Wireless/RT2870/RT2870STA.dat /etc/Wireless/RT2870STA/RT2870STA.dat
fi

