#!/bin/sh -e
#
# Copyright (c) 2015 Per Dalgas Jakobsen <pdj@knaldgas.dk>
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
#
#Based on:
# am355x_evm.sh by Robert Nelson


#
# Auto-configuring the usb0 network interface:
#
# If udhcpd has been installed it will be used for usb0.
# If udhcpd has not been installed, and dnsmasq is installed, dnsmasq
# is checked and possibly configured with usb0.
#

# Get usb0 set-up from /etc/network/interfaces - Used for
# auto-configuring the usb0 networking.

# RO users, use udhcpd...

unset deb_etc_dir \
      deb_network_interfaces \
      deb_udhcpd_conf \
      deb_udhcpd_default \
      deb_dnsmasq_conf \
      deb_dnsmasq_dir


# Separated /etc variable to ease test on host system (by changing
# etc_dir during test).
deb_etc_dir=/etc
#deb_ro_dir=$(mktemp -d)

deb_udhcpd_conf=${deb_etc_dir}/udhcpd.conf
deb_udhcpd_default=${deb_etc_dir}/default/udhcpd

deb_generated_dnsmasq_file=usb0-dhcp
deb_dnsmasq_conf=${deb_etc_dir}/dnsmasq.d/${deb_generated_dnsmasq_file}
deb_dnsmasq_dir=${deb_etc_dir}/dnsmasq.d

deb_network_interfaces=${deb_etc_dir}/network/interfaces

deb_configure_udhcpd ()
{
	# Function expects udhcpd to be installed, and usb_address,
	# usb_gateway and usb_netmask to be set.
	#
	# if udhcpd is installed, we will use it for usb0 networking.

	unset deb_udhcpd_disabled_regex \
	      deb_deb_udhcpd_interface \
	      deb_deb_udhcpd_start \
	      deb_deb_udhcpd_mask

	# Ensure that udhcpd has been disable. (comment out if needed).
	deb_udhcpd_disabled_regex='^[[:space:]]*DHCPD_ENABLED[[:space:]]*=[[:space:]]*"no"'
	$( ( grep -iqE "${deb_udhcpd_disabled_regex}" ${deb_udhcpd_default} && \
	    sed -ir "s/${deb_udhcpd_disabled_regex}/#\0/g" ${deb_udhcpd_default} ) || \
	  true)

	cat <<EOF > ${deb_udhcpd_conf}
# Managed by $0 - Do not modify unless you know what you are doing!
start      ${deb_usb_gateway}
end        ${deb_usb_gateway}
interface  usb0
max_leases 1
option subnet ${deb_usb_netmask}
option domain local
option lease 30
EOF

	unset test_udhcpd
	test_udhcpd=$(cat /etc/default/udhcpd | grep -v '#' | grep ${deb_udhcpd_conf} || true)
	if [ "x${test_udhcpd}" = "x" ] ; then
		sed -i -e 's:DHCPD_OPTS:#DHCPD_OPTS:g'  /etc/default/udhcpd
		echo "DHCPD_OPTS=\"-S /etc/udhcpd.conf\"" >> /etc/default/udhcpd
	fi
	# Will start or restart udhcpd
	/etc/init.d/udhcpd restart || true
}


deb_configure_dnsmasq ()
{
	# Function expects dnsmasq to be installed.
	# dnsmasq is installed, we may use it for usb0 networking.

	unset deb_usb0_handled \
	      deb_dnsmasq_warning

	# Check if any interface references usb0.
	# Only dnsmasq default directory and patterns are searched !!!
	deb_usb0_handled=$(grep -rlE --exclude='*~' --exclude='.*' \
				--exclude=${deb_generated_dnsmasq_file} \
				--exclude=.${deb_generated_dnsmasq_file} \
				--exclude=${deb_generated_dnsmasq_file}~ \
				'^[[:space:]]*interface[[:space:]]*=[[:space:]]*usb0' \
				${deb_dnsmasq_dir} || true)
	if [ "x$deb_usb0_handled" = "x" ]; then
		# No-one else is managing usb0, so we will:
		# We will only generate the file if it already exist or:
		#   if not, only if the file has not been disabled.
		if [ -f ${deb_dnsmasq_dir}/${deb_generated_dnsmasq_file} -o \
		     ! -f ${deb_dnsmasq_dir}/${deb_generated_dnsmasq_file}~ -a \
		     ! -f ${deb_dnsmasq_dir}/.${deb_generated_dnsmasq_file} ] ; then
			cat <<EOF > ${deb_dnsmasq_dir}/${deb_generated_dnsmasq_file}
# Managed by $0 - Do not modify unless you know what you are doing!
# Disable this file by prepending "." or appending "~" to the filename.
# Removing the file will just cause $0 to recreated!
#
# disable DNS by setting port to 0
#port=0
#one address range
dhcp-range=usb,${deb_usb_address},${deb_usb_gateway},20m
dhcp-option=usb,3
# either use listen-address, then include 127.0.0.1
#listen-address=${deb_usb_address}
#listen-address=127.0.0.1
# or bind to the usb0 interface (which implicitly also binds to lo)
interface=usb0
no-dhcp-interface=lo
EOF
			/sbin/ifconfig usb0 ${deb_usb_address} netmask ${deb_usb_netmask} || true
		fi

		deb_dnsmasq_warning="# NOTE: dnsmasq is partly configured by $0 - Changing configuration directory or file inclusion/exclusion may affect its functionality!"
		grep -qi "${deb_dnsmasq_warning}" ${deb_dnsmasq_conf} || \
			echo "\n${deb_dnsmasq_warning}" >>${deb_dnsmasq_conf}

		if [ -f /var/lib/misc/dnsmasq.leases ] ; then
			systemctl stop dnsmasq || true
			rm -rf /var/lib/misc/dnsmasq.leases || true
			systemctl start dnsmasq || true
		else
			systemctl restart dnsmasq || true
		fi
	fi
}



###  Script start ###

unset deb_iface_range_regex \
      deb_usb_address \
      deb_usb_gateway \
      deb_usb_netmask \
      deb_post_up \
      deb_dns_nameservers

deb_iface_range_regex="/^[[:space:]]*iface[[:space:]]+usb0/,/iface/"

deb_usb_address=$(sed -nr "${deb_iface_range_regex} p" ${deb_network_interfaces} |\
		  sed -nr "s/^[[:space:]]*address[[:space:]]+([0-9.]+)/\1/p")

deb_usb_gateway=$(sed -nr "${deb_iface_range_regex} p" ${deb_network_interfaces} |\
		  sed -nr "s/^[[:space:]]*gateway[[:space:]]+([0-9.]+)/\1/p")

deb_usb_netmask=$(sed -nr "${deb_iface_range_regex} p" ${deb_network_interfaces} |\
		  sed -nr "s/^[[:space:]]*netmask[[:space:]]+([0-9.]+)/\1/p")

deb_post_up=$(sed -nr "${deb_iface_range_regex} p" ${deb_network_interfaces} |\
              sed -nr "s/^[[:space:]]*post-up[[:space:]]+(.*)/\1/p")

deb_dns_nameservers=$(sed -nr "${deb_iface_range_regex} p" ${deb_network_interfaces} |\
                      sed -nr "s/^[[:space:]]*dns-nameservers[[:space:]]+(.*)/\1/p")

# Check if usb0 was specified in /etc/network/interfaces
if [ "x${deb_usb_address}" != "x" -a\
     "x${deb_usb_gateway}" != "x" -a\
     "x${deb_usb_netmask}" != "x" ] ; then

	until [ -d /sys/class/net/usb0/ ] ; do
		sleep 3
		echo "g_multi: waiting for /sys/class/net/usb0/"
	done

	if [ -d /sys/kernel/config/usb_gadget ] ; then
		/sbin/ifconfig usb0 ${deb_usb_address} netmask ${deb_usb_netmask} || true
	else
		unset dnsmasq_got_usb0
		#bbgw, SoftAp0/usb0 taken care of by dnsmasq..
		if [ -f /etc/dnsmasq.d/SoftAp0 ] ; then
			dnsmasq_got_usb0=$(cat /etc/dnsmasq.d/SoftAp0 | grep usb0 || true)
		fi

		if [ ! "x${dnsmasq_got_usb0}" = "x" ]; then
			#bbgw, pass's out: 192.168.7.3 & 192.168.7.4
			/sbin/ifconfig usb0 ${deb_usb_address} netmask ${deb_usb_netmask} || true
		# usb0 is specified!
		elif [ -f ${deb_udhcpd_default} ]; then
			/sbin/ifconfig usb0 ${deb_usb_address} netmask ${deb_usb_netmask} || true
			deb_configure_udhcpd

		elif [ -f ${deb_dnsmasq_dir}/README ]; then
			deb_configure_dnsmasq

		fi
	fi
	${deb_post_up}
	[ "x$deb_dns_nameservers" != "x" ] && echo nameserver $deb_dns_nameservers >> /etc/resolv.conf
fi

#
