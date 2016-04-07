#!/bin/sh -e

check_dpkg () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}" >/dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}

unset deb_pkgs
pkg="bison"
check_dpkg
pkg="build-essential"
check_dpkg
pkg="flex"
check_dpkg
pkg="git-core"
check_dpkg

if [ "${deb_pkgs}" ] ; then
	echo "Installing: ${deb_pkgs}"
	sudo apt-get update
	sudo apt-get -y install ${deb_pkgs}
	sudo apt-get clean
fi

git_sha="origin/master"
project="dtc"
server="git://git.kernel.org/pub/scm/utils/dtc"

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	git clone ${server}/${project}.git ${HOME}/git/${project}/
fi

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	rm -rf ${HOME}/git/${project}/ || true
	echo "error: git failure, try re-runing"
	exit
fi

cd ${HOME}/git/${project}/
make clean
git checkout master -f
git pull || true

test_for_branch=$(git branch --list ${git_sha}-build)
if [ "x${test_for_branch}" != "x" ] ; then
	git branch ${git_sha}-build -D
fi

git checkout ${git_sha} -b ${git_sha}-build
git pull --no-edit https://github.com/pantoniou/dtc dt-overlays5

make clean
make PREFIX=/usr/local/ CC=gcc CROSS_COMPILE= all
echo "Installing into: /usr/local/bin/"
sudo make PREFIX=/usr/local/ install
