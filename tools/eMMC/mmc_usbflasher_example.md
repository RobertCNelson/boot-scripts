Start with the generic flashing image "usbflasher", this supports ALL blank boards. This image will flash the eeprom and write a specific end image to the eMMC.

Step 1: usbflasher
```
voodoo@hades:~$ wget https://rcn-ee.net/rootfs/bb.org/testing/2016-04-10/usbflasher/BBB-blank-debian-8.4-usbflasher-armhf-2016-04-10-4gb.img.xz
voodoo@hades:~$ wget https://rcn-ee.net/rootfs/bb.org/testing/2016-04-10/usbflasher/BBB-blank-debian-8.4-usbflasher-armhf-2016-04-10-4gb.bmap
voodoo@hades:~$ bmaptool --version
bmaptool 3.2
```
```
voodoo@hades:~$ lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0 465.8G  0 disk 
└─sda1   8:1    0 465.8G  0 part /
sdb      8:16   1  14.9G  0 disk 
└─sdb1   8:17   1  14.9G  0 part 
```
Step 2: write usbflasher to media
```
voodoo@hades:~$ sudo bmaptool copy BBB-blank-debian-8.4-usbflasher-armhf-2016-04-10-4gb.img.xz /dev/sdb
bmaptool: info: discovered bmap file 'BBB-blank-debian-8.4-usbflasher-armhf-2016-04-10-4gb.bmap'
bmaptool: info: block map format version 2.0
bmaptool: info: 870400 blocks of size 4096 (3.3 GiB), mapped 134250 blocks (524.4 MiB or 15.4%)
bmaptool: info: copying image 'BBB-blank-debian-8.4-usbflasher-armhf-2016-04-10-4gb.img.xz' to block device '/dev/sdb' using bmap file 'BBB-blank-debian-8.4-usbflasher-armhf-2016-04-10-4gb.bmap'
bmaptool: info: 100% copied
bmaptool: info: synchronizing '/dev/sdb'
bmaptool: info: copying time: 1m 20.9s, copying speed 6.5 MiB/sec
```
```
voodoo@hestia:~$ sudo e2fsck -yf /dev/sdb1
e2fsck 1.42.13 (17-May-2015)
Pass 1: Checking inodes, blocks, and sizes
Deleted inode 26485 has zero dtime.  Fix? yes

Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information

rootfs: ***** FILE SYSTEM WAS MODIFIED *****
rootfs: 24503/217728 files (0.0% non-contiguous), 147471/870144 blocks
```
```
voodoo@hestia:~$ lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0 119.2G  0 disk 
└─sda1   8:1    0 119.2G  0 part /
sdb      8:16   1  14.9G  0 disk 
└─sdb1   8:17   1   3.3G  0 part
```
By default, the usbflasher will take up around "~500M", leaving 2.5G free for your flashing *.img.
```
voodoo@hades:~$ mkdir /tmp/flasher
voodoo@hades:~$ sudo mount /dev/sdb1 /tmp/flasher/
voodoo@hades:~$ df -h /tmp/flasher/
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdb1       3.3G  459M  2.6G  15% /tmp/flasher
voodoo@hades:~$ sudo umount /tmp/flasher
```
Step 3: setup final image:
mmc mode: The 'usbflasher' will read 'job.txt' file off mmc, to write eeprom/emmc
```
voodoo@hestia:~$ lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0 119.2G  0 disk 
└─sda1   8:1    0 119.2G  0 part /
sdb      8:16   1  14.9G  0 disk 
└─sdb1   8:17   1  14.9G  0 part
```
```
voodoo@hades:~$ mkdir /tmp/flasher
voodoo@hades:~$ sudo mount /dev/sdb1 /tmp/flasher/
voodoo@hades:~$ cd /tmp/flasher/opt/
voodoo@hades:/tmp/flasher/opt$ sudo mkdir emmc
voodoo@hades:/tmp/flasher/opt$ cd emmc/
```
Select the image you'd like to flash to the eMMC: "bone-debian-8.4-iot-armhf-2016-04-10-4gb"
```
voodoo@hades:/tmp/flasher/opt/emmc$ sudo wget https://rcn-ee.net/rootfs/bb.org/testing/2016-04-10/iot/bone-debian-8.4-iot-armhf-2016-04-10-4gb.img.xz
voodoo@hades:/tmp/flasher/opt/emmc$ sudo wget https://rcn-ee.net/rootfs/bb.org/testing/2016-04-10/iot/bone-debian-8.4-iot-armhf-2016-04-10-4gb.bmap
voodoo@hades:/tmp/flasher/opt/emmc$ sudo wget https://rcn-ee.net/rootfs/bb.org/testing/2016-04-10/iot/bone-debian-8.4-iot-armhf-2016-04-10-4gb.img.xz.job.txt

voodoo@hades:/tmp/flasher/opt/emmc$ ls -1
bone-debian-8.4-iot-armhf-2016-04-10-4gb.bmap
bone-debian-8.4-iot-armhf-2016-04-10-4gb.img.xz
bone-debian-8.4-iot-armhf-2016-04-10-4gb.img.xz.job.txt
```
```
voodoo@hades:/tmp/flasher/opt/emmc$ cat bone-debian-8.4-iot-armhf-2016-04-10-4gb.img.xz.job.txt
abi=aaa
conf_image=bone-debian-8.4-iot-armhf-2016-04-10-4gb.img.xz
conf_bmap=bone-debian-8.4-iot-armhf-2016-04-10-4gb.bmap
conf_resize=enable
conf_partition1_startmb=1
conf_partition1_fstype=0x83
conf_root_partition=1
```
Step 4: eeprom flashing (optional)

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
voodoo@hades:/tmp/flasher/opt/emmc$ cat bone-debian-8.4-iot-armhf-2016-04-10-4gb.img.xz.job.txt
abi=aaa
conf_eeprom_file=bbgw-eeprom.dump
conf_eeprom_compare=335
conf_image=bone-debian-8.4-iot-armhf-2016-04-10-4gb.img.xz
conf_bmap=bone-debian-8.4-iot-armhf-2016-04-10-4gb.bmap
conf_resize=enable
conf_partition1_startmb=1
conf_partition1_fstype=0x83
conf_root_partition=1
```
Step 5: job.txt file
```
voodoo@hades:/tmp/flasher/opt/emmc$ sudo cp -v bone-debian-8.4-iot-armhf-2016-04-10-4gb.img.xz.job.txt job.txt
'bone-debian-8.4-iot-armhf-2016-04-10-4gb.img.xz.job.txt' -> 'job.txt'
```
```
voodoo@hades:/tmp/flasher/opt/emmc$ sync
voodoo@hades:/tmp/flasher/opt/emmc$ cd ~/

voodoo@hades:~$ df -h /tmp/flasher/
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdb1        15G  860M   13G   7% /tmp/flasher

voodoo@hades:~$ sudo umount /tmp/flasher 
```
