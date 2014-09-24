#!/bin/bash -e

files () {
	echo "file list"
	#libfm-data (1.2.2.siduction.2) 
	#libfm-dbg (1.2.2.siduction.2) 
	#libfm-dev (1.2.2.siduction.2) 
	#libfm-doc (1.2.2.siduction.2) 
	#libfm-extra4 (1.2.2.siduction.2) 
	#libfm-gtk-data (1.2.2.siduction.2) 
	#libfm-gtk-dbg (1.2.2.siduction.2) 
	#libfm-gtk-dev (1.2.2.siduction.2) 
	#libfm-gtk4 (1.2.2.siduction.2) 
	#libfm-modules (1.2.2.siduction.2) 
	#libfm-modules-dbg (1.2.2.siduction.2) 
	#libfm-qt5-1 (0.8.0-2) 
	#libfm-qt5-dbg (0.8.0-2) 
	#libfm-qt5-dev (0.8.0-2) 
	#libfm-tools (1.2.2.siduction.2) 
	#libfm4 (1.2.2.siduction.2) 
	#liblxqt-globalkeys-qt5-0 (0.7.96-1) 
	#liblxqt-globalkeys-qt5-0-dev (0.7.96-1) 
	#liblxqt-globalkeys-ui-qt5-0 (0.7.96-1) 
	#liblxqt-globalkeys-ui-qt5-0-dev (0.7.96-1) 
	#liblxqt-qt5-0 (0.7.96-1) 
	#liblxqt-qt5-0-dbg (0.7.96-1) 
	#liblxqt-qt5-0-dev (0.7.96-1) 
	#liblxqtmount-qt5-0 (0.7.96-1) 
	#liblxqtmount-qt5-0-dbg (0.7.96-1) 
	#liblxqtmount-qt5-0-dev (0.7.96-1) 
	#libsysstat-qt5-0 (0.1.0-2) 
	#libsysstat-qt5-0-dbg (0.1.0-2) 
	#libsysstat-qt5-0-dev (0.1.0-2) 
	#lxappearance (0.5.5.siduction.5) 
	#lxappearance-dbg (0.5.5.siduction.5) 
	#lximage-qt (0.2.0.siduction.5) 
	#lximage-qt-dbg (0.2.0.siduction.5) 
	#lxqt-about-qt5 (0.7.96-1) 
	#lxqt-admin-qt5 (0.7.96-1) 
	#lxqt-admin-qt5-dbg (0.7.96-1) 
	#lxqt-common-qt5 (0.7.96-1) 
	#lxqt-config-qt5 (0.7.96-1) 
	#lxqt-config-qt5-dbg (0.7.96-1) 
	#lxqt-globalkeys-qt5 (0.7.96-1) 
	#lxqt-notificationd-qt5 (0.7.96-1) 
	#lxqt-notificationd-qt5-dbg (0.7.96-1) 
	#lxqt-openssh-askpass-qt5 (0.7.96-1) 
	#lxqt-openssh-askpass-qt5-dbg (0.7.96-1) 
	#lxqt-panel-qt5 (0.7.96-1) 
	#lxqt-panel-qt5-dbg (0.7.96-1) 
	#lxqt-policykit-qt5 (0.7.96-1) 
	#lxqt-policykit-qt5-dbg (0.7.96-1) 
	#lxqt-power (0.7.0.siduction.5) 
	#lxqt-power-dbg (0.7.0.siduction.5) 
	#lxqt-powermanagement-qt5 (0.7.96-2) 
	#lxqt-powermanagement-qt5-dbg (0.7.96-2) 
	#lxqt-qtplugin-qt5 (0.7.96-2) 
	#lxqt-qtplugin-qt5-dbg (0.7.96-2) 
	#lxqt-runner-qt5 (0.7.96-1) 
	#lxqt-runner-qt5-dbg (0.7.96-1) 
	#lxqt-session-qt5 (0.7.96-1) 
	#lxqt-session-qt5-dbg (0.7.96-1) 
	#pcmanfm (1.2.2.siduction.1) 
	#pcmanfm-dbg (1.2.2.siduction.1) 
	#pcmanfm-qt5 (0.8.0-2) 
	#pcmanfm-qt5-dbg (0.8.0-2) 
}

build_pkg () {
	if [ ! -f ${deb_file} ] ; then
		wget -c ${mirror}/${location}/${package}_${pkg_version}-${deb_version}.dsc
		wget -c ${mirror}/${location}/${package}_${pkg_version}.orig.tar.${orig_comp}
		wget -c ${mirror}/${location}/${package}_${pkg_version}-${deb_version}.debian.tar.xz

		dpkg-source -x ${package}_${pkg_version}-${deb_version}.dsc
		cd ${package}-${pkg_version}/
		dpkg-buildpackage -rfakeroot -b -uc
		cd ../
		ls | grep -v debian | grep .deb
	fi
}

build_siduction_pkg () {
	if [ ! -f ${deb_file} ] ; then
		wget -c ${mirror}/${location}/${package}_${pkg_version}.dsc
		wget -c ${mirror}/${location}/${package}_${pkg_version}.tar.xz

		dpkg-source -x ${package}_${pkg_version}.dsc
		cd ${package}-${pkg_version}/
		dpkg-buildpackage -rfakeroot -b -uc
		cd ../
		ls | grep -v debian | grep .deb
	fi
}

mkdir -p build
cd build

deb_arch=$(dpkg --print-architecture)

mirror="http://packages.siduction.org"

package="compton-conf"
location="lxqt/pool/main/c/${package}"
pkg_version="0.1.0"
deb_version="1"
deb_file="compton-conf-qt5_${pkg_version}-${deb_version}_${deb_arch}.deb"
orig_comp="bz2"

build_pkg

package="polkit-qt-1"
location="lxqt/pool/main/p/${package}"
pkg_version="0.112.0"
deb_version="1"
deb_file="libpolkit-qt-1-dev_${pkg_version}-${deb_version}_${deb_arch}.deb"
orig_comp="bz2"


build_pkg

package="obconf-qt"
location="lxqt/pool/main/o/${package}"
pkg_version="0.1.0"
deb_version="1"
deb_file="obconf-qt5_${pkg_version}-${deb_version}_${deb_arch}.deb"
orig_comp="bz2"


build_pkg

package="libqtxdg"
location="lxqt/pool/main/libq/${package}"
pkg_version="1.0.0"
deb_version="1"
deb_file="libqt5xdg-dev_${pkg_version}-${deb_version}_${deb_arch}.deb"
orig_comp="gz"

build_pkg

package="lxmenu-data"
location="lxqt/pool/main/l/${package}"
pkg_version="0.1.4.siduction.1"
deb_file="lxmenu-data_${pkg_version}_all.deb"

build_siduction_pkg

package="lxappearance"
deb_package="lxmenu-data"
location="lxqt/pool/main/l/${package}"
pkg_version="0.5.5.siduction.5"
deb_file="lxappearance_${pkg_version}_${deb_arch}.deb"

build_siduction_pkg

#wip:

#needs: lxmenu-data

package="libfm"
deb_package="obconf-qt5"
location="lxqt/pool/main/libf/${package}"
pkg_version="1.2.2.siduction.2"

#if [ ! -f ${deb_package}_${pkg_version}-${deb_version}_${deb_arch}.deb ] ; then
	wget -c ${mirror}/${location}/${package}_${pkg_version}.dsc
	wget -c ${mirror}/${location}/${package}_${pkg_version}.tar.xz

	dpkg-source -x ${package}_${pkg_version}.dsc
	cd ${package}-${pkg_version}/
	dpkg-buildpackage -rfakeroot -b
	cd ../
#fi


#libqt5xdg-dev
package="libsysstat"
deb_package="obconf-qt5"
location="lxqt/pool/main/libs/${package}"
pkg_version="0.1.0"
deb_version="2"
orig_comp="bz2"

#if [ ! -f ${deb_package}_${pkg_version}-${deb_version}_${deb_arch}.deb ] ; then
	wget -c ${mirror}/${location}/${package}_${pkg_version}-${deb_version}.dsc
	wget -c ${mirror}/${location}/${package}_${pkg_version}.orig.tar.${orig_comp}
	wget -c ${mirror}/${location}/${package}_${pkg_version}-${deb_version}.debian.tar.xz

	dpkg-source -x ${package}_${pkg_version}-${deb_version}.dsc
	cd ${package}-${pkg_version}/
	dpkg-buildpackage -rfakeroot -b
	cd ../
#fi

#libfm-dev

package="pcmanfm-qt"
deb_package="bconf-qt5"
location="lxqt/pool/main/p/${package}"
pkg_version="0.8.0"
deb_version="2"
orig_comp="bz2"

#if [ ! -f ${deb_package}_${pkg_version}-${deb_version}_${deb_arch}.deb ] ; then
	wget -c ${mirror}/${location}/${package}_${pkg_version}-${deb_version}.dsc
	wget -c ${mirror}/${location}/${package}_${pkg_version}.orig.tar.${orig_comp}
	wget -c ${mirror}/${location}/${package}_${pkg_version}-${deb_version}.debian.tar.xz

	dpkg-source -x ${package}_${pkg_version}-${deb_version}.dsc
	cd ${package}-${pkg_version}/
	dpkg-buildpackage -rfakeroot -b
	cd ../
#fi

#
