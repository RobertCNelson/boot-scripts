#!/bin/bash
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
apt-get update
# Hit http://security.debian.org jessie/updates InRelease
# Hit http://repos.rcn-ee.com jessie InRelease  
# Hit https://deb.nodesource.com jessie InRelease                           
# Ign http://httpredir.debian.org jessie InRelease                          
# Get:1 http://security.debian.org jessie/updates/main armhf Packages [425 kB]
# Hit http://httpredir.debian.org jessie-updates InRelease                  
# Get:2 http://repos.rcn-ee.com jessie/main armhf Packages [771 kB]         
# Hit http://httpredir.debian.org jessie Release.gpg                        
# Get:3 https://deb.nodesource.com jessie/main armhf Packages [968 B]       
# Hit http://httpredir.debian.org jessie Release                            
# Get:4 http://security.debian.org jessie/updates/contrib armhf Packages [994 B]
# Get:5 http://security.debian.org jessie/updates/non-free armhf Packages [20 B]
# Get:6 http://httpredir.debian.org jessie-updates/main armhf Packages [17.6 kB]
# Get:7 http://httpredir.debian.org jessie-updates/contrib armhf Packages [20 B]
# Get:8 http://httpredir.debian.org jessie-updates/non-free armhf Packages [450 B]
# Get:9 http://httpredir.debian.org jessie/main armhf Packages [8,850 kB] 
# Get:10 http://httpredir.debian.org jessie/contrib armhf Packages [44.7 kB]
# Get:11 http://httpredir.debian.org jessie/non-free armhf Packages [74.9 kB]
# Fetched 10.2 MB in 19s (519 kB/s)                                         
# Reading package lists... Done
apt-get install -y mjpg-streamer
install -m 644 51a4d83c8180e259bcb5661002712166/mjpg-streamer.rules /etc/udev/rules.d
install -m 644 51a4d83c8180e259bcb5661002712166/mjpg-streamer.service /etc/systemd/system
systemctl restart mjpg-streamer