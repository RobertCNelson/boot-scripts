#!/bin/sh

sudo systemctl disable bonescript.socket
sudo sed -i -e 's:8080:80:g' /etc/apache2/ports.conf
sudo sed -i -e 's:8080:80:g' /etc/apache2/sites-enabled/000-default.conf
sudo /etc/init.d/apache2 restart
