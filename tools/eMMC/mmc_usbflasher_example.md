
Start with the generic flashing image "usbflasher", this supports ALL blank boards. This image will flash the eeprom and write a specific end image to the eMMC.

Step 1: Download 'usbflasher', and write it to a microSD:

```
voodoo@hades:~$ wget https://rcn-ee.net/rootfs/bb.org/testing/2016-04-03/usbflasher/BBB-blank-debian-8.4-usbflasher-armhf-2016-04-03-4gb.img.xz
voodoo@hades:~$ wget https://rcn-ee.net/rootfs/bb.org/testing/2016-04-03/usbflasher/BBB-blank-debian-8.4-usbflasher-armhf-2016-04-03-4gb.bmap
voodoo@hades:~$ bmaptool --version
bmaptool 3.2
```

```
voodoo@hades:~$ sudo bmaptool copy BBB-blank-debian-8.4-usbflasher-armhf-2016-04-03-4gb.img.xz /dev/sde

bmaptool: info: discovered bmap file 'BBB-blank-debian-8.4-usbflasher-armhf-2016-04-03-4gb.bmap'
bmaptool: info: block map format version 2.0
bmaptool: info: 435200 blocks of size 4096 (1.7 GiB), mapped 125515 blocks (490.3 MiB or 28.8%)
bmaptool: info: copying image 'BBB-blank-debian-8.4-usbflasher-armhf-2016-04-03-4gb.img.xz' to block device '/dev/sde' using bmap file 'BBB-blank-debian-8.4-usbflasher-armhf-2016-04-03-4gb.bmap'
bmaptool: info: 100% copied
bmaptool: info: synchronizing '/dev/sde'
bmaptool: info: copying time: 1m 6.4s, copying speed 7.4 MiB/sec
```

Step 2: You need to decide, usb or mmc mode for the flasher:

usb mode: The 'usbflasher' will mount a USB drive (fat formated, windows/linux/mac), and read a 'job.txt' file, to write eeprom/emmc

mmc mode: The 'usbflasher' will read 'job.txt' file off mmc, to write eeprom/emmc

```
voodoo@hades:~$ lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0 465.8G  0 disk 
└─sda1   8:1    0 465.8G  0 part /
sde      8:64   1  14.9G  0 disk 
└─sde1   8:65   1   3.6G  0 part
```

Step 3: usb (secondary fat flash drive) / mmc (microsd with usbflasher)

```
voodoo@hades:~$ mkdir /tmp/flasher
voodoo@hades:~$ sudo mount /dev/sde1 /tmp/flasher/
voodoo@hades:~$ cd /tmp/flasher/opt/
voodoo@hades:/tmp/flasher/opt$ sudo mkdir emmc
voodoo@hades:/tmp/flasher/opt$ cd emmc/
```

Select the image you'd like to flash to the eMMC: "bone-debian-8.4-iot-armhf-2016-04-03-4gb"

```
voodoo@hades:/tmp/flasher/opt/emmc$ sudo wget https://rcn-ee.net/rootfs/bb.org/testing/2016-04-03/iot/bone-debian-8.4-iot-armhf-2016-04-03-4gb.img.xz
voodoo@hades:/tmp/flasher/opt/emmc$ sudo wget https://rcn-ee.net/rootfs/bb.org/testing/2016-04-03/iot/bone-debian-8.4-iot-armhf-2016-04-03-4gb.bmap
voodoo@hades:/tmp/flasher/opt/emmc$ sudo wget https://rcn-ee.net/rootfs/bb.org/testing/2016-04-03/iot/bone-debian-8.4-iot-armhf-2016-04-03-4gb.img.xz.job.txt

voodoo@hades:/tmp/flasher/opt/emmc$ ls -1
bone-debian-8.4-iot-armhf-2016-04-03-4gb.bmap
bone-debian-8.4-iot-armhf-2016-04-03-4gb.img.xz
bone-debian-8.4-iot-armhf-2016-04-03-4gb.img.xz.job.txt
```

```
voodoo@hades:/tmp/flasher/opt/emmc$ cat bone-debian-8.4-iot-armhf-2016-04-03-4gb.img.xz.job.txt
abi=aaa
conf_image=bone-debian-8.4-iot-armhf-2016-04-03-4gb.img.xz
conf_bmap=bone-debian-8.4-iot-armhf-2016-04-03-4gb.bmap
conf_resize=enable
conf_partition1_startmb=1
conf_partition1_fstype=0x83
conf_root_partition=1
```

For eeprom "flashing" we need 2 more settings..

```
conf_eeprom_file=<file>
conf_eeprom_compare=<6-8>
```

```
voodoo@hades:/tmp/flasher/opt/emmc$ sudo wget https://raw.githubusercontent.com/RobertCNelson/boot-scripts/master/device/bone/bbgw-eeprom.dump

voodoo@hades:/tmp/flasher/opt/emmc$ hexdump bbgw-eeprom.dump 
0000000 55aa ee33 3341 3533 4e42 544c 5747 4131
0000010 3030 3030 3030 3030 3030 3030          
000001c
voodoo@hades:/tmp/flasher/opt/emmc$ hexdump bbgw-eeprom.dump -c
0000000   �   U   3   �   A   3   3   5   B   N   L   T   G   W   1   A
0000010   0   0   0   0   0   0   0   0   0   0   0   0                
000001c
```

```
voodoo@hades:/tmp/flasher/opt/emmc$ cat bone-debian-8.4-iot-armhf-2016-04-03-4gb.img.xz.job.txt
abi=aaa
conf_eeprom_file=bbgw-eeprom.dump
conf_eeprom_compare=335
conf_image=bone-debian-8.4-iot-armhf-2016-04-03-4gb.img.xz
conf_bmap=bone-debian-8.4-iot-armhf-2016-04-03-4gb.bmap
conf_resize=enable
conf_partition1_startmb=1
conf_partition1_fstype=0x83
conf_root_partition=1
```

Rename as 'job.txt'
```
voodoo@hades:/tmp/flasher/opt/emmc$ sudo cp -v bone-debian-8.4-iot-armhf-2016-04-03-4gb.img.xz.job.txt job.txt
'bone-debian-8.4-iot-armhf-2016-04-03-4gb.img.xz.job.txt' -> 'job.txt'
```

```
voodoo@hades:/tmp/flasher/opt/emmc$ sync
voodoo@hades:/tmp/flasher/opt/emmc$ cd ~/

voodoo@hades:~$ df -h /tmp/flasher/
Filesystem      Size  Used Avail Use% Mounted on
/dev/sde1        15G  860M   13G   7% /tmp/flasher

voodoo@hades:~$ sudo umount /tmp/flasher 
```
