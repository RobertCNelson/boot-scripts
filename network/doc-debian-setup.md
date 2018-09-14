
```bash
sudo sysctl net.ipv4.ip_forward=1
```

Assuming: eth0 is your PC port, and the Beagle is eth1
```
sudo iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
sudo iptables --append FORWARD --in-interface eth1 -j ACCEPT
```

