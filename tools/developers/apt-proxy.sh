#!/bin/bash -e

echo "Acquire::http::Proxy \"http://apt-proxy.local:3142/\";" > /tmp/apt.conf
echo "Acquire::PDiffs \"false\";" >> /tmp/apt.conf
sudo cp -v /tmp/apt.conf /etc/apt/apt.conf

