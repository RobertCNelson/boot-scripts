#!/bin/bash -e

sudo apt-get update ; sudo apt-get -y install cmake automake gtk-doc-tools libqt4-dev libx11-dev pkg-config libglib2.0-dev libpango1.0-dev valac libmagic-dev libstatgrab-dev

git clone git://git.lxde.org/git/lxde/lxqt.git
cd lxqt
sed -i -e 's/git@git.lxde.org:/git:\/\/git.lxde.org\/git/g' .gitmodules
git submodule init
git submodule update --remote --rebase
