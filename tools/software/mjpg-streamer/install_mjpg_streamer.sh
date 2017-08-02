#!/bin/bash

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

cat /etc/dogtag
# BeagleBoard.org Debian Image 2017-01-17
uname -a
# Linux blue-dc5d 4.4.41-ti-r83 #1 SMP Tue Jan 17 00:01:19 UTC 2017 armv7l GNU/Linux
lsusb
# Bus 001 Device 002: ID 046d:0825 Logitech, Inc. Webcam C270
# Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
if [ -d /dev/video0 ] ; then
	v4l2-ctl --info
fi

if [ ! -f /usr/bin/mjpg_streamer ] ; then
	apt update
	apt install -y mjpg-streamer
fi

install -m 644 ./mjpg-streamer.rules /etc/udev/rules.d
install -m 644 ./mjpg-streamer.service /etc/systemd/system
systemctl daemon-reload || true
systemctl restart mjpg-streamer || true
