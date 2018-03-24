#!/bin/bash

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

echo "**********************************************"
ln -s -f /usr/bin/rc_balance /etc/roboticscape/link_to_startup_program
echo "systemctl daemon-reload"
systemctl daemon-reload
echo "Enabling roboticscape Service"
systemctl enable roboticscape
echo "Enabling rc_battery_monitor Service"
systemctl enable rc_battery_monitor
# try to start battery monitor, but ignore errors as this may not work
echo "Starting rc_battery_monitor Service"
set +e
systemctl start rc_battery_monitor

echo "Rebooting..."
reboot
