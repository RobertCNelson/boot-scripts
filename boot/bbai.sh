#!/bin/sh -e
#

log="BeagleBone-AI:"

#Make sure the cpu_thermal zone is enabled...
if [ -f /sys/class/thermal/thermal_zone0/mode ] ; then
	echo enabled > /sys/class/thermal/thermal_zone0/mode
fi

if [ -f /usr/bin/cpufreq-set ] ; then
	echo "${log} cpufreq-set -g powersave" 
	/usr/bin/cpufreq-set -g powersave || true
fi

check_getty_tty=$(systemctl is-active serial-getty@ttyGS0.service || true)
if [ "x${check_getty_tty}" = "xinactive" ] ; then
	systemctl restart serial-getty@ttyGS0.service || true
fi
