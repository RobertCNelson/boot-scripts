#!/bin/bash -e

files () {
	echo "file list"

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

#on repos.rcn-ee.net
#package="compton-conf"
#location="lxqt/pool/main/c/${package}"
#pkg_version="0.1.0"
#deb_version="1"
#deb_file="compton-conf-qt5_${pkg_version}-${deb_version}_${deb_arch}.deb"
#orig_comp="bz2"
#
#build_pkg

#on repos.rcn-ee.net
#package="polkit-qt-1"
#location="lxqt/pool/main/p/${package}"
#pkg_version="0.112.0"
#deb_version="1"
#deb_file="libpolkit-qt-1-dev_${pkg_version}-${deb_version}_${deb_arch}.deb"
#orig_comp="bz2"
#
#build_pkg

#on repos.rcn-ee.net
#package="obconf-qt"
#location="lxqt/pool/main/o/${package}"
#pkg_version="0.1.0"
#deb_version="1"
#deb_file="obconf-qt5_${pkg_version}-${deb_version}_${deb_arch}.deb"
#orig_comp="bz2"
#
#build_pkg

#on repos.rcn-ee.net
#package="libqtxdg"
#location="lxqt/pool/main/libq/${package}"
#pkg_version="1.0.0"
#deb_version="1"
#deb_file="libqt5xdg-dev_${pkg_version}-${deb_version}_${deb_arch}.deb"
#orig_comp="gz"
#
#build_pkg

#on repos.rcn-ee.net
#package="lxmenu-data"
#location="lxqt/pool/main/l/${package}"
#pkg_version="0.1.4.siduction.1"
#deb_file="lxmenu-data_${pkg_version}_all.deb"
#
#build_siduction_pkg

#on repos.rcn-ee.net
#package="lxappearance"
#location="lxqt/pool/main/l/${package}"
#pkg_version="0.5.5.siduction.5"
#deb_file="lxappearance_${pkg_version}_${deb_arch}.deb"
#
#build_siduction_pkg

#on repos.rcn-ee.net
#package="liblxqt-mount"
#location="lxqt/pool/main/libl/${package}"
#pkg_version="0.7.96"
#deb_version="1"
#deb_file="liblxqtmount-qt5-0-dev_${pkg_version}-${deb_version}_${deb_arch}.deb"
#orig_comp="bz2"
#
#build_pkg

#on repos.rcn-ee.net
#sudo dpkg -i build/libqt5xdg-dev_1.0.0-1_amd64.deb  build/libqt5xdg1_1.0.0-1_amd64.deb
#package="liblxqt"
#location="lxqt/pool/main/libl/${package}"
#pkg_version="0.7.96"
#deb_version="1"
#orig_comp="bz2"
#deb_file="liblxqt-qt5-0-dev_${pkg_version}-${deb_version}_${deb_arch}.deb"
#
#build_pkg

#on repos.rcn-ee.net
#package="libsysstat"
#location="lxqt/pool/main/libs/${package}"
#pkg_version="0.1.0"
#deb_version="2"
#orig_comp="bz2"
#deb_file="libsysstat-qt5-0-dev_${pkg_version}-${deb_version}_${deb_arch}.deb"
#
#build_pkg

#on repos.rcn-ee.net
#sudo dpkg -i build/liblxqt-qt5-0-dev_0.7.96-1_amd64.deb build/liblxqt-qt5-0_0.7.96-1_amd64.deb
#package="lxqt-globalkeys"
#location="lxqt/pool/main/l/${package}"
#pkg_version="0.7.96"
#deb_version="1"
#orig_comp="bz2"
#deb_file="liblxqt-globalkeys-qt5-0-dev_${pkg_version}-${deb_version}_${deb_arch}.deb"
#
#build_pkg

#on repos.rcn-ee.net
#package="libfm"
#location="lxqt/pool/main/libf/${package}"
#pkg_version="1.2.2.siduction.2"
#deb_file="libfm-dev_${pkg_version}_${deb_arch}.deb"
#
#build_siduction_pkg

#on repos.rcn-ee.net
#sudo dpkg -i build/libfm4*.deb build/libfm*.deb build/lxmenu-data_0.1.4.siduction.1_all.deb 
#package="pcmanfm-qt"
#location="lxqt/pool/main/p/${package}"
#pkg_version="0.8.0"
#deb_version="2"
#orig_comp="bz2"
#deb_file="pcmanfm-qt5_${pkg_version}-${deb_version}_${deb_arch}.deb"
#
#build_pkg

#on repos.rcn-ee.net
#package="pcmanfm"
#location="lxqt/pool/main/p/${package}"
#pkg_version="1.2.2.siduction.1"
#deb_file="x_${pkg_version}_${deb_arch}.deb"
#
#build_siduction_pkg

#sudo dpkg -i build/libfm-qt5-dev_0.8.0-2_amd64.deb build/libfm-qt5-1_0.8.0-2_amd64.deb
package="lximage-qt"
location="lxqt/pool/main/l/${package}"
pkg_version="0.2.0.siduction.5"
deb_file="lximage-qt_${pkg_version}_${deb_arch}.deb"

build_siduction_pkg




#
