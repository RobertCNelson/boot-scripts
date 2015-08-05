#!/bin/bash -e

#based on: http://www.embeddedsystemtesting.com/2015/03/how-to-run-iperf-traffic-on-same.html?m=1

#hardware: cross over cable between eth0 & eth1
#softwarew: iperf

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

mac_eth0=$(ifconfig -a | grep eth0 | awk '{print $5}')
mac_eth1=$(ifconfig -a | grep eth1 | awk '{print $5}')

ifconfig eth0 10.50.0.1 netmask 255.255.255.0
ifconfig eth1 10.50.1.1 netmask 255.255.255.0

iptables -t nat -L
iptables -t nat -A POSTROUTING -s 10.50.0.1 -d 10.60.1.1 -j SNAT --to-source 10.60.0.1
iptables -t nat -A PREROUTING -d 10.60.0.1 -j DNAT --to-destination 10.50.0.1
iptables -t nat -A POSTROUTING -s 10.50.1.1 -d 10.60.0.1 -j SNAT --to-source 10.60.1.1
iptables -t nat -A PREROUTING -d 10.60.1.1 -j DNAT --to-destination 10.50.1.1

ip route add 10.60.1.1 dev eth0
arp -i eth0 -s 10.60.1.1 ${mac_eth1}
ip route add 10.60.0.1 dev eth1
arp -i eth1 -s 10.60.0.1 ${mac_eth0}

ping -c 1 10.60.1.1

echo ""

echo "#Start Server"
echo "iperf -B 10.50.0.1 -s -u -w 320k -l 1KB &"
echo ""
echo "#Run Client"
echo "iperf -B 10.50.1.1 -c 10.60.0.1 -u -b 1000M -w 320k -l 1KB -P 10 -t 60"

#-l 1KB
#[SUM]  0.0-60.0 sec  1.37 GBytes   197 Mbits/sec

#-l 4KB
#[SUM]  0.0-60.3 sec  1.14 GBytes   163 Mbits/sec

#-l 8KB
#[SUM]  0.0-60.3 sec   405 MBytes  56.3 Mbits/sec
