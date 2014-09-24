#!/bin/bash -e

mkdir -p build
cd build

mirror="http://packages.siduction.org"
package="libqtxdg"
location="lxqt/pool/main/libq/${package}"
pkg_version="1.0.0"
deb_version="-1"

wget -c ${mirror}/${location}/${package}_${pkg_version}-${deb_version}.dsc
wget -c ${mirror}/${location}/${package}_${pkg_version}.orig.tar.gz
wget -c ${mirror}/${location}/${package}_${pkg_version}-${deb_version}.debian.tar.xz

dpkg-source -x ${package}_${pkg_version}-${deb_version}.dsc
cd ${package}_${pkg_version}/
dpkg-buildpackage -rfakeroot -b

