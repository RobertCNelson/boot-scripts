#!/bin/bash -e

#git_sha="origin/master"
#git_sha="27cdc1b16f86f970c3c049795d4e71ad531cca3d"
#git_sha="fdc7387845420168ee5dd479fbe4391ff93bddab"
git_sha="65cc4d2748a2c2e6f27f1cf39e07a5dbabd80ebf"
project="dtc"
server="git://git.kernel.org/pub/scm/linux/kernel/git/jdl"

if [ ! -f /tmp/git/ ] ; then
	mkdir -p /tmp/git/ || true
fi

git clone ${server}/${project}.git /tmp/git/${project}/

cd /tmp/git/${project}/
make clean
git checkout master -f
git pull || true

git checkout ${git_sha} -b ${git_sha}-build
git pull git://github.com/RobertCNelson/dtc.git dtc-fixup-65cc4d2

make clean
make PREFIX=/usr/local/ CC=gcc CROSS_COMPILE= all
echo "Installing into: /usr/local/bin/"
make PREFIX=/usr/local/ install
