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
v4l2-ctl --info
# Driver Info (not using libv4l2):
#         Driver name   : uvcvideo
#         Card type     : UVC Camera (046d:0825)
#         Bus info      : usb-musb-hdrc.1.auto-1
#         Driver version: 4.4.41
#         Capabilities  : 0x84200001
#                 Video Capture
#                 Streaming
#                 Extended Pix Format
#                 Device Capabilities
#         Device Caps   : 0x04200001
#                 Video Capture
#                 Streaming
#                 Extended Pix Format
#apt-get install -y libv4l-dev libjpeg-dev imagemagick subversion
#svn co https://svn.code.sf.net/p/mjpg-streamer/code/mjpg-streamer mjpg-streamer
# SVN_REV="3:172"
#cd mjpg-streamer
#make
#./mjpg_streamer ./mjpg_streamer -i "./input_uvc.so -yuv" -o "./output_http.so -p 8090 -w ./www"
#make install
#mjpg_streamer -i "/usr/local/lib/input_uvc.so -yuv" -o "/usr/local/lib/output_http.so -p 8090 -w /usr/local/www"

if [ ! -f /usr/bin/mjpg_streamer ] ; then
	apt update
	apt install -y mjpg-streamer
fi

install -m ./mjpg-streamer.rules /etc/udev/rules.d
install -m ./mjpg-streamer.service /etc/systemd/system
systemctl restart mjpg-streamer
