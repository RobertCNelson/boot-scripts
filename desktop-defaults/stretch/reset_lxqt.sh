#!/bin/bash

rm -rf /home/${USER}/.config/lxqt || true
rm -rf /home/${USER}/.config/pcmanfm-qt || true

cp -rf /opt/scripts/desktop-defaults/jessie/stretch/* /home/${USER}/.config

sync
