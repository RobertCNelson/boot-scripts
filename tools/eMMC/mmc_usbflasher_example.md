
Start with the generic flashing image "usbflasher", this supports ALL blank boards. This image will flash the eeprom and write a specific end image to the eMMC.

Step 1: Download 'usbflasher', and write it to a microSD:

```
voodoo@hades:~$ wget https://rcn-ee.net/rootfs/bb.org/testing/2016-03-13/usbflasher/BBB-blank-debian-8.3-usbflasher-armhf-2016-03-13-2gb.img.xz
voodoo@hades:~$ wget https://rcn-ee.net/rootfs/bb.org/testing/2016-03-13/usbflasher/BBB-blank-debian-8.3-usbflasher-armhf-2016-03-13-2gb.bmap
voodoo@hades:~$ bmaptool --version
bmaptool 3.2
```

```
voodoo@hades:~$ sudo bmaptool copy BBB-blank-debian-8.3-usbflasher-armhf-2016-03-13-2gb.img.xz /dev/sde

bmaptool: info: discovered bmap file 'BBB-blank-debian-8.3-usbflasher-armhf-2016-03-13-2gb.bmap'
bmaptool: info: block map format version 2.0
bmaptool: info: 435200 blocks of size 4096 (1.7 GiB), mapped 125515 blocks (490.3 MiB or 28.8%)
bmaptool: info: copying image 'BBB-blank-debian-8.3-usbflasher-armhf-2016-03-13-2gb.img.xz' to block device '/dev/sde' using bmap file 'BBB-blank-debian-8.3-usbflasher-armhf-2016-03-13-2gb.bmap'
bmaptool: info: 100% copied
bmaptool: info: synchronizing '/dev/sde'
bmaptool: info: copying time: 1m 6.4s, copying speed 7.4 MiB/sec
```

Step 2: You need to decide, usb or mmc mode for the flasher:

usb mode: The 'usbflasher' will mount a USB drive (fat formated, windows/linux/mac), and read a 'job.txt' file, to write eeprom/emmc

mmc mode: The 'usbflasher' will read 'job.txt' file off mmc, to write eeprom/emmc

For mmc mode, we need to expand the microSD:

```
voodoo@hades:~$ lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0 465.8G  0 disk 
└─sda1   8:1    0 465.8G  0 part /
sde      8:64   1  14.9G  0 disk 
└─sde1   8:65   1   1.7G  0 part
```

Depending on what version of sfdisk:

```
voodoo@hades:~$ sudo sfdisk --version
sfdisk from util-linux 2.27.1
```

sfdisk >= 2.26.x

```
sudo sfdisk /dev/sde <<-__EOF__
1M,,L,*
__EOF__
```

sfdisk <= 2.25.x

```
sudo sfdisk --in-order --Linux --unit M /dev/sde <<-__EOF__
1,,L,*
__EOF__
```

Then resize:

```
voodoo@hades:~$ sudo e2fsck -f /dev/sde1
e2fsck 1.42.13 (17-May-2015)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
rootfs: 24376/108864 files (0.0% non-contiguous), 131223/434944 blocks

voodoo@hades:~$ sudo resize2fs /dev/sde1
resize2fs 1.42.13 (17-May-2015)
Resizing the filesystem on /dev/sde1 to 3889280 (4k) blocks.
The filesystem on /dev/sde1 is now 3889280 (4k) blocks long.
```

```
voodoo@hades:~$ lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0 465.8G  0 disk 
└─sda1   8:1    0 465.8G  0 part /
sde      8:64   1  14.9G  0 disk 
└─sde1   8:65   1  14.9G  0 part 
```

Step 3: usb/mmc

```
voodoo@hades:~$ mkdir /tmp/flasher
voodoo@hades:~$ sudo mount /dev/sde1 /tmp/flasher/
voodoo@hades:~$ cd /tmp/flasher/opt/
voodoo@hades:/tmp/flasher/opt$ sudo mkdir emmc
voodoo@hades:/tmp/flasher/opt$ cd emmc/
```

```
voodoo@hades:/tmp/flasher/opt/emmc$ sudo wget https://rcn-ee.net/rootfs/bb.org/testing/2016-03-13/iot/bone-debian-8.3-iot-armhf-2016-03-13-4gb.img.xz
voodoo@hades:/tmp/flasher/opt/emmc$ sudo wget https://rcn-ee.net/rootfs/bb.org/testing/2016-03-13/iot/bone-debian-8.3-iot-armhf-2016-03-13-4gb.bmap
voodoo@hades:/tmp/flasher/opt/emmc$ sudo wget https://rcn-ee.net/rootfs/bb.org/testing/2016-03-13/iot/bone-debian-8.3-iot-armhf-2016-03-13-4gb.img.xz.job.txt

voodoo@hades:/tmp/flasher/opt/emmc$ ls -lh
total 404M
-rw-r--r-- 1 root root 5.1K Mar 13 13:27 bone-debian-8.3-iot-armhf-2016-03-13-4gb.bmap
-rw-r--r-- 1 root root 404M Mar 14 10:49 bone-debian-8.3-iot-armhf-2016-03-13-4gb.img.xz
-rw-r--r-- 1 root root  218 Mar 13 13:27 bone-debian-8.3-iot-armhf-2016-03-13-4gb.img.xz.job.txt
```

```
voodoo@hades:/tmp/flasher/opt/emmc$ cat bone-debian-8.3-iot-armhf-2016-03-13-4gb.img.xz.job.txt
abi=aaa
conf_image=bone-debian-8.3-iot-armhf-2016-03-13-4gb.img.xz
conf_bmap=bone-debian-8.3-iot-armhf-2016-03-13-4gb.bmap
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
voodoo@hades:/tmp/flasher/opt/emmc$ cat bone-debian-8.3-iot-armhf-2016-03-13-4gb.img.xz.job.txt
abi=aaa
conf_eeprom_file=bbgw-eeprom.dump
conf_eeprom_compare=335
conf_image=bone-debian-8.3-iot-armhf-2016-03-13-4gb.img.xz
conf_bmap=bone-debian-8.3-iot-armhf-2016-03-13-4gb.bmap
conf_resize=enable
conf_partition1_startmb=1
conf_partition1_fstype=0x83
conf_root_partition=1
```

```
voodoo@hades:/tmp/flasher/opt/emmc$ sudo cp -v bone-debian-8.3-iot-armhf-2016-03-13-4gb.img.xz.job.txt job.txt
'bone-debian-8.3-iot-armhf-2016-03-13-4gb.img.xz.job.txt' -> 'job.txt'
```

```
voodoo@hades:/tmp/flasher/opt/emmc$ sync
voodoo@hades:/tmp/flasher/opt/emmc$ cd ~/
voodoo@hades:~$ sudo umount /tmp/flasher 
```
