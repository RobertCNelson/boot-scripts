#!/bin/bash -e

echo "Acquire::http::Proxy \"http://apt-proxy:3142/\";" > /tmp/apt.conf
echo "Acquire::PDiffs \"false\";" >> /tmp/apt.conf
sudo cp -v /tmp/apt.conf /etc/apt/apt.conf

echo "deb http://ftp.us.debian.org/debian/ jessie main contrib non-free" > /tmp/sources.list
echo "deb http://ftp.us.debian.org/debian/ jessie-updates main contrib non-free" >> /tmp/sources.list
echo "deb http://security.debian.org/ jessie/updates main contrib non-free" >> /tmp/sources.list
echo "deb [arch=armhf] http://repos.rcn-ee.com/debian/ jessie main" >> /tmp/sources.list
echo "deb [arch=armhf] http://repos.rcn-ee.com/debian-exp/ jessie main" >> /tmp/sources.list

sudo cp -v /tmp/sources.list /etc/apt/sources.list
