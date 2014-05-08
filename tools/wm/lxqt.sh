#!/bin/bash -e

git clone git://git.lxde.org/git/lxde/lxqt.git
cd lxqt
sed -i -e 's/git@git.lxde.org:/git:\/\/git.lxde.org\/git/g' .gitmodules
git submodule init
git submodule update --remote --rebase
