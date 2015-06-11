#!/bin/sh -e
#
# Copyright (c) 2014 Robert Nelson <robertcnelson@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

get_device () {
	machine=$(cat /proc/device-tree/model | sed "s/ /_/g")

	if [ "x${SOC}" = "x" ] ; then
		case "${machine}" in
		TI_AM335x_BeagleBone|TI_AM335x_BeagleBone_Black)
			uname -r | grep ti >/dev/null && SOC="ti"
			if [ "x${SOC}" = "x" ] ; then
				SOC="omap-psp"
			fi
			;;
		TI_AM5728_BeagleBoard-X15)
			SOC="ti"
			;;
		TI_OMAP5_uEVM_board)
			SOC="armv7-lpae"
			;;
		*)
			echo "Machine: [${machine}]"
			SOC="armv7"
			;;
		esac
	fi
}

update_uEnv_txt () {
	if [ ! -f /etc/kernel/postinst.d/zz-uenv_txt ] ; then
		if [ -f /boot/uEnv.txt ] ; then
			older_kernel=$(grep uname_r /boot/uEnv.txt | awk -F"=" '{print $2}')
			sed -i -e "s:uname_r=$older_kernel:uname_r=$latest_kernel:g" /boot/uEnv.txt
			echo "info: /boot/uEnv.txt: `grep uname_r /boot/uEnv.txt`"
			if [ ! "x${older_kernel}" = "x${latest_kernel}" ] ; then
				echo "info: [${latest_kernel}] now installed and will be used on the next reboot..."
			fi
		fi
	fi

	if [ "x${daily_cron}" = "xenabled" ] ; then
		touch /tmp/daily_cron.reboot
	fi
}

check_dpkg () {
	echo "Checking dpkg..."
	unset deb_pkgs
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}$" >/dev/null || deb_pkgs="${pkg}"
}

check_apt_cache () {
	echo "Checking apt-cache..."
	unset apt_cache
	apt_cache=$(LC_ALL=C apt-cache search "^${pkg}$" | awk '{print $1}' || true)
}

latest_version_repo () {
	if [ ! "x${SOC}" = "x" ] ; then
		cd /tmp/
		if [ -f /tmp/LATEST-${SOC} ] ; then
			rm -f /tmp/LATEST-${SOC} || true
		fi

		echo "info: checking archive"
		wget ${mirror}/${dist}-${arch}/LATEST-${SOC}
		if [ -f /tmp/LATEST-${SOC} ] ; then
			latest_kernel=$(cat /tmp/LATEST-${SOC} | grep ${kernel} | awk '{print $3}')
			echo "debug: your are running: [`uname -r`]"
			echo "debug: latest is: [${latest_kernel}]"

			pkg="linux-image-${latest_kernel}"
			#is the package installed?
			check_dpkg
			#is the package even available to apt?
			check_apt_cache
			if [ "x${deb_pkgs}" = "x${apt_cache}" ] ; then
				echo "debug: installing: [${pkg}]"
				apt-get install -y ${pkg}
				update_uEnv_txt
			elif [ "x${pkg}" = "x${apt_cache}" ] ; then
				if [ "x${daily_cron}" = "xenabled" ] ; then
					apt-get clean
					exit
				fi
				echo "debug: reinstalling: [${pkg}]"
				apt-get install -y ${pkg} --reinstall
				update_uEnv_txt
			else
				echo "info: [${pkg}] (latest) is currently unavailable on [rcn-ee.com/repos]"
			fi
		fi
	fi
}

#Only for the original May 2014 image, everything should use the repo's now..
latest_version () {
	if [ ! "x${SOC}" = "x" ] ; then
		cd /tmp/
		if [ -f /tmp/LATEST-${SOC} ] ; then
			rm -f /tmp/LATEST-${SOC} || true
		fi

		echo "info: checking archive"
		wget ${mirror}/${dist}-${arch}/LATEST-${SOC}
		if [ -f /tmp/LATEST-${SOC} ] ; then
			latest_kernel=$(cat /tmp/LATEST-${SOC} | grep ${kernel} | awk '{print $3}')
			echo "debug: your are running: [${current_kernel}]"
			echo "debug: latest is: [${latest_kernel}]"

			if [ ! "x${current_kernel}" = "x${latest_kernel}" ] ; then
				distro=$(lsb_release -is)
				if [ "x${distro}" = "xDebian" ] ; then
					wget -c https://rcn-ee.com/repos/debian/pool/main/l/linux-upstream/linux-image-${latest_kernel}_1${dist}_${arch}.deb
				else
					wget -c https://rcn-ee.com/repos/ubuntu/pool/main/l/linux-upstream/linux-image-${latest_kernel}_1${dist}_${arch}.deb
				fi
				if [ -f /tmp/linux-image-${latest_kernel}_1${dist}_${arch}.deb ] ; then
					dpkg -i /tmp/linux-image-${latest_kernel}_1${dist}_${arch}.deb
					sync

					if [ -f /boot/vmlinuz-${latest_kernel} ] ; then
						bootdir="/boot/uboot"

						if [ -f ${bootdir}/zImage_bak ] ; then
							rm ${bootdir}/zImage_bak
							sync
						fi

						if [ -f ${bootdir}/zImage ] ; then
							echo "Backing up ${bootdir}/zImage as ${bootdir}/zImage_bak..."
							mv -v ${bootdir}/zImage ${bootdir}/zImage_bak
							sync
						fi

						if [ -f ${bootdir}/initrd.bak ] ; then
							rm ${bootdir}/initrd.bak
							sync
						fi

						if [ -f ${bootdir}/initrd.img ] ; then
							echo "Backing up ${bootdir}/initrd.img as ${bootdir}/initrd.bak..."
							mv -v ${bootdir}/initrd.img ${bootdir}/initrd.bak
							sync
						fi

						if [ -d ${bootdir}/dtbs_bak/ ] ; then
							rm -rf ${bootdir}/dtbs_bak/ || true
							sync
						fi

						if [ -d ${bootdir}/dtbs/ ] ; then
							echo "Backing up ${bootdir}/dtbs/ as ${bootdir}/dtbs_bak/..."
							mv ${bootdir}/dtbs/ ${bootdir}/dtbs_bak/ || true
							sync
						fi

						if [ -d /boot/dtbs/${latest_kernel}/ ] ; then
							mkdir -p ${bootdir}/dtbs/
							cp /boot/dtbs/${latest_kernel}/*.dtb ${bootdir}/dtbs/ 2>/dev/null || true
							sync
						fi

						if [ ! -f /boot/initrd.img-${latest_kernel} ] ; then
							echo "Creating /boot/initrd.img-${latest_kernel}"
							update-initramfs -c -k ${latest_kernel}
							sync
						else
							echo "Updating /boot/initrd.img-${latest_kernel}"
							update-initramfs -u -k ${latest_kernel}
							sync
						fi

						cp -v /boot/vmlinuz-${latest_kernel} ${bootdir}/zImage
						cp -v /boot/initrd.img-${latest_kernel} ${bootdir}/initrd.img
					fi
				fi
			fi
		fi
	fi
}

specific_version_repo () {
	latest_kernel=$(echo ${kernel_version})

	pkg="linux-image-${latest_kernel}"
	#is the package installed?
	check_dpkg
	#is the package even available to apt?
	check_apt_cache
	if [ "x${deb_pkgs}" = "x${apt_cache}" ] ; then
		apt-get install -y ${pkg}
		update_uEnv_txt
	elif [ "x${pkg}" = "x${apt_cache}" ] ; then
		apt-get install -y ${pkg} --reinstall
		update_uEnv_txt
	else
		echo "error: [${pkg}] unavailable"
	fi
}

third_party_final () {
	depmod -a ${latest_kernel}
	update-initramfs -uk ${latest_kernel}
}

third_party () {
	if [ "x${SOC}" = "xomap-psp" ] ; then
		apt-get install -o Dpkg::Options::="--force-overwrite" -y mt7601u-modules-${latest_kernel}

		third_party_final
	fi

	if [ "x${SOC}" = "xti" ] ; then
		apt-get install -o Dpkg::Options::="--force-overwrite" -y mt7601u-modules-${latest_kernel}

		apt-get install -y ti-sgx-es8-modules-${latest_kernel}
		third_party_final
	fi
}

checkparm () {
	if [ "$(echo $1|grep ^'\-')" ] ; then
		echo "E: Need an argument"
		exit
	fi
}

if [ ! -f /usr/bin/lsb_release ] ; then
	echo "install lsb-release"
	exit
fi

dist=$(lsb_release -cs)
arch=$(dpkg --print-architecture)
current_kernel=$(uname -r)

kernel="STABLE"
mirror="https://rcn-ee.com/repos/latest"
unset rcn_mirror
unset kernel_version
unset daily_cron
# parse commandline options
while [ ! -z "$1" ] ; do
	case $1 in
	--use-rcn-mirror)
		mirror="http://rcn-ee.homeip.net:81/dl/mirrors/deb"
		rcn_mirror="enabled"
		;;
	--kernel)
		checkparm $2
		kernel_version="$2"
		;;
	--daily-cron)
		daily_cron="enabled"
		;;
	--beta-kernel)
		kernel="TESTING"
		;;
	--exp-kernel)
		kernel="EXPERIMENTAL"
		;;
	--ti-kernel)
		SOC="ti"
		;;
	esac
	shift
done


if [ ! -f /lib/systemd/system/systemd-timesyncd.service ] ; then
	if [ -f /usr/sbin/ntpdate ] ; then
		echo "syncing local clock to pool.ntp.org"
		ntpdate -s pool.ntp.org || true
	fi
fi

test_rcnee=$(cat /etc/apt/sources.list | grep rcn-ee || true)
if [ ! "x${test_rcnee}" = "x" ] ; then
	net_rcnee=$(cat /etc/apt/sources.list | grep repos.rcn-ee.net || true)
	if [ ! "x${net_rcnee}" = "x" ] ; then
		sed -i -e 's:repos.rcn-ee.net:repos.rcn-ee.com:g' /etc/apt/sources.list
	fi
	apt-get update
	get_device

	if [ "x${kernel_version}" = "x" ] ; then
		latest_version_repo
	else
		specific_version_repo
	fi
	third_party
	apt-get clean
else
	get_device
	latest_version
fi
#third_party
#
