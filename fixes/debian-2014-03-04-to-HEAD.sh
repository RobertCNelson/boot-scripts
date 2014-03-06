#!/bin/sh

check_dpkg () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}$" >/dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}

if [ -f /etc/Wireless/RT2870/RT2870STA.dat ] ; then
	#fixed: https://github.com/rcn-ee/farm/commit/f5e66c19decc06954f00509913a4a2cdf1afd7bc
	echo "MT601: Moving RT2870STA.dat to /etc/Wireless/RT2870STA/RT2870STA.dat"
	sudo mkdir -p /etc/Wireless/RT2870STA/ || true
	sudo mv /etc/Wireless/RT2870/RT2870STA.dat /etc/Wireless/RT2870STA/RT2870STA.dat
fi

unset deb_pkgs
pkg="beaglebone"
check_dpkg
#fixed: https://github.com/beagleboard/image-builder/commit/1b4caa3de385414674b734157f6bf1d487e0cd9d
pkg="libopencv-dev"
check_dpkg
#fixed: https://github.com/beagleboard/image-builder/commit/6af879606f2638dda363c54264e8e72ddb032b98
pkg="libopencv-core-dev"
check_dpkg
#fixed: https://github.com/beagleboard/image-builder/commit/1c0e5f8f272c6e3a3b659ea7e3854abe5c81df40

if [ "${deb_pkgs}" ] ; then
	sudo apt-get update
	sudo apt-get -y install ${deb_pkgs}
fi

