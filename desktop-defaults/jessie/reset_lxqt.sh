#!/bin/bash

rm -rf /home/${USER}/.config/lxqt || true
rm -rf /home/${USER}/.config/openbox || true
rm -rf /home/${USER}/.config/pcmanfm-qt || true

cp -rf /opt/scripts/desktop-defaults/jessie/lxqt/* /home/${USER}/.config

sync
