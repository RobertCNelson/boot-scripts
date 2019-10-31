
```bash
sudo sysctl net.ipv4.ip_forward=1
```

Assuming: eth0 is your PC port, and the Beagle is eth1
```
sudo iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
sudo iptables --append FORWARD --in-interface eth1 -j ACCEPT
```

Starting with Debian Buster, nf_tables is now default, to switch back..
```
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
sudo update-alternatives --set arptables /usr/sbin/arptables-legacy
sudo update-alternatives --set ebtables /usr/sbin/ebtables-legacy
```
