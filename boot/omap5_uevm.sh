#!/bin/sh -e
#
# Copyright (c) 2013-2015 Robert Nelson <robertcnelson@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#Make sure the cpu_thermal zone is enabled...
if [ -f /sys/class/thermal/thermal_zone0/mode ] ; then
	echo enabled > /sys/class/thermal/thermal_zone0/mode
fi

#Just Cleanup /etc/issue, systemd starts up tty before these are updated...
sed -i -e '/Address/d' /etc/issue || true

#Disabling Non-Valid Services..
unset check_service
check_service=$(systemctl is-enabled bb-bbai-tether.service || true)
if [ "x${check_service}" = "xenabled" ] ; then
	echo "${log} systemctl: disable bb-bbai-tether.service"
	systemctl disable bb-bbai-tether.service || true
fi
unset check_service
check_service=$(systemctl is-enabled robotcontrol.service || true)
if [ "x${check_service}" = "xenabled" ] ; then
	echo "${log} systemctl: disable robotcontrol.service"
	systemctl disable robotcontrol.service || true
	rm -f /etc/modules-load.d/robotcontrol_modules.conf || true
fi
unset check_service
check_service=$(systemctl is-enabled rc_battery_monitor.service || true)
if [ "x${check_service}" = "xenabled" ] ; then
	echo "${log} systemctl: rc_battery_monitor.service"
	systemctl disable rc_battery_monitor.service || true
fi

#
