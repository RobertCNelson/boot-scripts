#!/bin/bash -e
#
# This script is alibrary of common functions used by the other scripts in the current directory
# It is meant to be sourced by the other scripts, NOT executed.
# Source it like this:
# source $(dirname "$0")/functions.sh

version_message="1.20161005: sfdisk: actually calculate the start of 2nd/3rd partitions..."
emmcscript="cmdline=init=/opt/scripts/tools/eMMC/$(basename $0)"

check_if_run_as_root(){
  if ! id | grep -q root; then
    echo "must be run as root"
    exit
  fi
}

find_root_drive(){
  unset root_drive
  root_drive="$(cat /proc/cmdline | sed 's/ /\n/g' | grep root=UUID= | awk -F 'root=' '{print $2}' || true)"
  if [ ! "x${root_drive}" = "x" ] ; then
    root_drive="$(/sbin/findfs ${root_drive} || true)"
  else
    root_drive="$(cat /proc/cmdline | sed 's/ /\n/g' | grep root= | awk -F 'root=' '{print $2}' || true)"
  fi
}

flush_cache () {
  sync
  blockdev --flushbufs ${destination}
}

broadcast () {
  if [ "x${message}" != "x" ] ; then
    echo "${message}"
    echo "${message}" > /dev/tty0 || true
  fi
}

echo_broadcast() {
  local _message="$1"
  if [ "x${_message}" != "x" ] ; then
    echo "${_message}"
    echo "${_message}" > /dev/tty0 || true
  fi
}

inf_loop () {
  while read MAGIC ; do
    case $MAGIC in
      beagleboard.org)
        echo "Your foo is strong!"
        bash -i
        ;;
      *)	echo "Your foo is weak."
        ;;
    esac
  done
}

# umount does not like device names without a valid /etc/mtab
# find the mount point from /proc/mounts
dev2dir () {
  grep -m 1 '^$1 ' /proc/mounts | while read LINE ; do set -- $LINE ; echo $2 ; done
}

get_device () {
  is_bbb="enable"
  machine=$(cat /proc/device-tree/model | sed "s/ /_/g")

  case "${machine}" in
    TI_AM5728_BeagleBoard*)
      unset is_bbb
      ;;
  esac
}

reset_leds() {
  if [ "x${is_bbb}" = "xenable" ] ; then
    [ -e /proc/$CYLON_PID ]  && kill $CYLON_PID > /dev/null 2>&1

    if [ -e /sys/class/leds/beaglebone\:green\:usr0/trigger ] ; then
      echo heartbeat > /sys/class/leds/beaglebone\:green\:usr0/trigger
      echo heartbeat > /sys/class/leds/beaglebone\:green\:usr1/trigger
      echo heartbeat > /sys/class/leds/beaglebone\:green\:usr2/trigger
      echo heartbeat > /sys/class/leds/beaglebone\:green\:usr3/trigger
    fi
  else
    echo_broadcast "We don't know how to reset the leds as we are not a BBB compatible device"
  fi

}

write_failure () {
  echo_broadcast "writing to [${destination}] failed..."

  reset_leds

  echo_broadcast "-----------------------------"
  flush_cache
  umount $(dev2dir ${destination}p1) > /dev/null 2>&1 || true
  umount $(dev2dir ${destination}p2) > /dev/null 2>&1 || true
  inf_loop
}

_do_we_have_eeprom() {
  unset got_eeprom
  #v8 of nvmem...
  if [ -f /sys/bus/nvmem/devices/at24-0/nvmem ] && [ "x${got_eeprom}" = "x" ] ; then
    eeprom="/sys/bus/nvmem/devices/at24-0/nvmem"
    eeprom_location="/sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/at24-0/nvmem"
    got_eeprom="true"
  fi

  #pre-v8 of nvmem...
  if [ -f /sys/class/nvmem/at24-0/nvmem ] && [ "x${got_eeprom}" = "x" ] ; then
    eeprom="/sys/class/nvmem/at24-0/nvmem"
    eeprom_location="/sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/nvmem/at24-0/nvmem"
    got_eeprom="true"
  fi

  #eeprom 3.8.x & 4.4 with eeprom-nvmem patchset...
  if [ -f /sys/bus/i2c/devices/0-0050/eeprom ] && [ "x${got_eeprom}" = "x" ] ; then
    eeprom="/sys/bus/i2c/devices/0-0050/eeprom"

    if [ -f /sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/eeprom ] ; then
      eeprom_location="/sys/devices/platform/ocp/44e0b000.i2c/i2c-0/0-0050/eeprom"
    else
      eeprom_location=$(ls /sys/devices/ocp*/44e0b000.i2c/i2c-0/0-0050/eeprom 2> /dev/null)
    fi

    got_eeprom="true"
  fi
}

check_eeprom () {
  echo_broadcast "Checking for Valid ${device_eeprom} header"

  _do_we_have_eeprom

  if [ "x${is_bbb}" = "xenable" ] ; then
    if [ "x${got_eeprom}" = "xtrue" ] ; then
      eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -n 8 | cut -b 6-8)
      if [ "x${eeprom_header}" = "x335" ] ; then
        echo_broadcast "Valid ${device_eeprom} header found [${eeprom_header}]"
        echo_broadcast "-----------------------------"
      else
        echo_broadcast "Invalid EEPROM header detected"
        if [ -f /opt/scripts/device/bone/${device_eeprom}.dump ] ; then
          if [ ! "x${eeprom_location}" = "x" ] ; then
            echo_broadcast "Writing header to EEPROM"
            dd if=/opt/scripts/device/bone/${device_eeprom}.dump of=${eeprom_location}
            sync
            sync
            eeprom_check=$(hexdump -e '8/1 "%c"' ${eeprom} -n 8 | cut -b 6-8)
            echo "eeprom check: [${eeprom_check}]"

            #We have to reboot, as the kernel only loads the eMMC cape
            # with a valid header
            reboot -f

            #We shouldnt hit this...
            exit
          fi
        else
          echo_broadcast "error: no [/opt/scripts/device/bone/${device_eeprom}.dump]"
        fi
      fi
    fi
  fi
}

check_running_system () {
  echo_broadcast "copying: [${source}] -> [${destination}]"
  echo_broadcast "lsblk:"
  echo_broadcast "`lsblk || true`"
  echo_broadcast "-----------------------------"
  echo_broadcast "df -h | grep rootfs:"
  echo_broadcast "`df -h | grep rootfs || true`"
  echo_broadcast "-----------------------------"

  if [ ! -b "${destination}" ] ; then
    echo_broadcast "Error: [${destination}] does not exist"
    write_failure
  fi

  if [ "x${is_bbb}" = "xenable" ] ; then
    if [ ! -e /sys/class/leds/beaglebone\:green\:usr0/trigger ] ; then
      modprobe leds_gpio || true
      sleep 1
    fi
  fi
}

cylon_leds () {
  if [ "x${is_bbb}" = "xenable" ] ; then
    if [ -e /sys/class/leds/beaglebone\:green\:usr0/trigger ] ; then
      BASE=/sys/class/leds/beaglebone\:green\:usr
      echo none > ${BASE}0/trigger
      echo none > ${BASE}1/trigger
      echo none > ${BASE}2/trigger
      echo none > ${BASE}3/trigger

      STATE=1
      while : ; do
        case $STATE in
          1)	echo 255 > ${BASE}0/brightness
            echo 0   > ${BASE}1/brightness
            STATE=2
            ;;
          2)	echo 255 > ${BASE}1/brightness
            echo 0   > ${BASE}0/brightness
            STATE=3
            ;;
          3)	echo 255 > ${BASE}2/brightness
            echo 0   > ${BASE}1/brightness
            STATE=4
            ;;
          4)	echo 255 > ${BASE}3/brightness
            echo 0   > ${BASE}2/brightness
            STATE=5
            ;;
          5)	echo 255 > ${BASE}2/brightness
            echo 0   > ${BASE}3/brightness
            STATE=6
            ;;
          6)	echo 255 > ${BASE}1/brightness
            echo 0   > ${BASE}2/brightness
            STATE=1
            ;;
          *)	echo 255 > ${BASE}0/brightness
            echo 0   > ${BASE}1/brightness
            STATE=2
            ;;
        esac
        sleep 0.1
      done
    fi
  fi
}

_build_uboot_spl_dd_options() {
  echo_broadcast "Figuring out options for SPL U-Boot copy ..."
  unset dd_spl_uboot
  if [ ! "x${dd_spl_uboot_count}" = "x" ] ; then
    dd_spl_uboot="${dd_spl_uboot}count=${dd_spl_uboot_count} "
  fi

  if [ ! "x${dd_spl_uboot_seek}" = "x" ] ; then
    dd_spl_uboot="${dd_spl_uboot}seek=${dd_spl_uboot_seek} "
  fi

  if [ ! "x${dd_spl_uboot_conf}" = "x" ] ; then
    dd_spl_uboot="${dd_spl_uboot}conv=${dd_spl_uboot_conf} "
  fi

  if [ ! "x${dd_spl_uboot_bs}" = "x" ] ; then
    dd_spl_uboot="${dd_spl_uboot}bs=${dd_spl_uboot_bs}"
  fi
  echo_broadcast "Will use : $dd_spl_uboot"
}

_build_uboot_dd_options() {
  echo_broadcast "Figuring out options for U-Boot copy ..."
  unset dd_uboot
  if [ ! "x${dd_uboot_count}" = "x" ] ; then
    dd_uboot="${dd_uboot}count=${dd_uboot_count} "
  fi

  if [ ! "x${dd_uboot_seek}" = "x" ] ; then
    dd_uboot="${dd_uboot}seek=${dd_uboot_seek} "
  fi

  if [ ! "x${dd_uboot_conf}" = "x" ] ; then
    dd_uboot="${dd_uboot}conv=${dd_uboot_conf} "
  fi

  if [ ! "x${dd_uboot_bs}" = "x" ] ; then
    dd_uboot="${dd_uboot}bs=${dd_uboot_bs}"
  fi
  echo_broadcast "Will use : $dd_uboot"
}

dd_bootloader () {
  echo_broadcast "Writing bootloader to [${destination}]"

  _build_uboot_spl_dd_options
  _build_uboot_dd_options

  echo_broadcast "-------------------------------------------------------------------"
  echo_broadcast "Copying SPL U-Boot with dd if=${dd_spl_uboot_backup} of=${destination} ${dd_spl_uboot}"
  dd if=${dd_spl_uboot_backup} of=${destination} ${dd_spl_uboot}
  echo_broadcast "-------------------------------------------------------------------"
  echo_broadcast "-------------------------------------------------------------------"
  echo_broadcast "Copying U-Boot with dd if=${dd_uboot_backup} of=${destination} ${dd_uboot}"
  dd if=${dd_uboot_backup} of=${destination} ${dd_uboot}
  echo_broadcast "-------------------------------------------------------------------"
}

format_boot () {
  echo_broadcast "-------------------------------------------------------------------"
  echo_broadcast "Formating boot partition with mkfs.vfat -F 16 ${destination}p1 -n ${boot_label}"
  LC_ALL=C mkfs.vfat -F 16 ${destination}p1 -n ${boot_label}
  echo_broadcast "-------------------------------------------------------------------"
  flush_cache
}

format_root () {
  echo_broadcast "-------------------------------------------------------------------"
  echo_broadcast "Formating rootfs with mkfs.ext4 ${ext4_options} ${destination}p2 -L ${rootfs_label}"
  LC_ALL=C mkfs.ext4 ${ext4_options} ${destination}p2 -L ${rootfs_label}
  echo_broadcast "-------------------------------------------------------------------"
  flush_cache
}

format_single_root () {
  echo_broadcast "-------------------------------------------------------------------"
  echo_broadcast "Formating rootfs with mkfs.ext4 ${ext4_options} ${destination}p1 -L ${boot_label}"
  LC_ALL=C mkfs.ext4 ${ext4_options} ${destination}p1 -L ${boot_label}
  echo_broadcast "-------------------------------------------------------------------"
  flush_cache
}

copy_boot () {
  #FIXME: Something is fishy about this function
  local tmp_boot_dir="/tmp/boot"
  echo_broadcast "-------------------------------------------------------------------"
  echo_broadcast "Copying: ${source}p1 -> ${destination}p1"
  echo_broadcast "==> Creating temporary boot directory (${tmp_boot_dir})"
  mkdir -p ${tmp_boot_dir} || true
  echo_broadcast "==> Mounting ${destination}p1 to ${tmp_boot_dir}"
  mount ${destination}p1 ${tmp_boot_dir} -o sync

  if [ -f /boot/uboot/MLO ] && [ -f /boot/uboot/u-boot.img ] ; then
    echo_broadcast "==> Found MLO and u-boot.img in current /boot/uboot/, copying"
    #Make sure the BootLoader gets copied first:
    cp -v /boot/uboot/MLO ${tmp_boot_dir}/MLO || write_failure
    flush_cache

    cp -v /boot/uboot/u-boot.img ${tmp_boot_dir}/u-boot.img || write_failure
    flush_cache
  else
    echo_broadcast "!==> We could not find an MLO and u-boot.img to copy"
  fi

  echo_broadcast "==> rsync: /boot/uboot/ -> ${tmp_boot_dir}"
  #FIXME: Why is it rsyncing /boot/uboot ? This is wrong
  #rsync -aAx /boot/uboot/ /tmp/boot/ --exclude={MLO,u-boot.img,uEnv.txt} || write_failure
  rsync -avAx /boot/* ${tmp_boot_dir} --exclude={MLO,u-boot.img,uEnv.txt} || write_failure
  flush_cache

  echo_broadcast "==> Unmounting ${tmp_boot_dir}"
  umount ${tmp_boot_dir} || umount -l ${tmp_boot_dir} || write_failure
  flush_cache
  #FIXME: When was this mounted ? Why is it going to be unmounted ?
  umount /boot/uboot || umount -l /boot/uboot || true
  echo_broadcast "-------------------------------------------------------------------"
}

copy_rootfs () {
  local tmp_rootfs_dir="/tmp/rootfs"
  echo_broadcast "-------------------------------------------------------------------"
  echo_broadcast "Copying: ${source}p${media_rootfs} -> ${destination}p${media_rootfs}"
  echo_broadcast "==> Creating temporary rootfs directory (${tmp_rootfs_dir})"
  mkdir -p ${tmp_rootfs_dir} || true
  echo_broadcast "==> Mounting ${destination}p${media_rootfs} to ${tmp_rootfs_dir}"
  mount ${destination}p${media_rootfs} ${tmp_rootfs_dir} -o async,noatime

  echo_broadcast "==> rsync: / -> ${tmp_rootfs_dir}"
  rsync -avAx /* ${tmp_rootfs_dir} --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found,/lib/modules/*,/uEnv.txt} || write_failure
  flush_cache

  if [ -d ${tmp_rootfs_dir}/etc/ssh/ ] ; then
    echo_broadcast "==> Applying SSH Key Regeneration trick"
    #ssh keys will now get regenerated on the next bootup
    touch ${tmp_rootfs_dir}/etc/ssh/ssh.regenerate
    flush_cache
  fi


  echo_broadcast "==> Copying: Kernel modules"
  echo_broadcast "===> Creating directory for modules"
  mkdir -p ${tmp_rootfs_dir}/lib/modules/$(uname -r)/ || true
  echo_broadcast "===> rsync: /lib/modules/$(uname -r)/ -> ${tmp_rootfs_dir}/lib/modules/$(uname -r)/"
  rsync -aAx /lib/modules/$(uname -r)/* ${tmp_rootfs_dir}/lib/modules/$(uname -r)/ || write_failure
  flush_cache

  echo_broadcast "Copying: ${source}p${media_rootfs} -> ${destination}p${media_rootfs} complete"

  echo_broadcast "Final System Tweaks:"
  echo_broadcast "==> Put root uuid in uEnv.txt"
  unset root_uuid
  root_uuid=$(/sbin/blkid -c /dev/null -s UUID -o value ${destination}p${media_rootfs})
  if [ "${root_uuid}" ] ; then
    sed -i -e 's:uuid=:#uuid=:g' ${tmp_rootfs_dir}/boot/uEnv.txt
    echo "uuid=${root_uuid}" >> ${tmp_rootfs_dir}/boot/uEnv.txt

    echo_broadcast "===> UUID=${root_uuid}"
    root_uuid="UUID=${root_uuid}"
  else
    #FIXME: really a failure...
    root_uuid="${source}p${media_rootfs}"
  fi

  echo_broadcast "==> Generating: /etc/fstab"
  echo "# /etc/fstab: static file system information." > ${tmp_rootfs_dir}/etc/fstab
  echo "#" >> ${tmp_rootfs_dir}/etc/fstab
  echo "${root_uuid}  /  ext4  noatime,errors=remount-ro  0  1" >> ${tmp_rootfs_dir}/etc/fstab
  echo "debugfs  /sys/kernel/debug  debugfs  defaults  0  0" >> ${tmp_rootfs_dir}/etc/fstab
  cat ${tmp_rootfs_dir}/etc/fstab

  #FIXME: What about when you boot from a fat partition /boot ?
  echo_broadcast "==> /boot/uEnv.txt: disabling eMMC flasher script"
  sed -i -e 's:'$emmcscript':#'$emmcscript':g' ${tmp_rootfs_dir}/boot/uEnv.txt
  cat ${tmp_rootfs_dir}/boot/uEnv.txt
  flush_cache

  echo_broadcast "==> Unmounting ${tmp_rootfs_dir}"
  umount ${tmp_rootfs_dir} || umount -l ${tmp_rootfs_dir} || write_failure

  if [ "x${is_bbb}" = "xenable" ] ; then
    echo_broadcast "==> Stop Cylon LEDs"
    [ -e /proc/$CYLON_PID ]  && kill $CYLON_PID
  fi

  echo_broadcast "==> Syncing: ${destination}"
  #https://github.com/beagleboard/meta-beagleboard/blob/master/contrib/bone-flash-tool/emmc.sh#L158-L159
  # force writeback of eMMC buffers
  sync
  dd if=${destination} of=/dev/null count=100000
  echo_broadcast "Syncing: ${destination} complete"
  echo_broadcast "-------------------------------------------------------------------"

  if [ -f /boot/debug.txt ] ; then
    echo_broadcast "This script has now completed its task"
    echo_broadcast "-----------------------------"
    echo_broadcast "debug: enabled"
    inf_loop
  else
    #FIXME: Why are we unmounting the host /tmp ?
    umount /tmp || umount -l /tmp
    if [ "x${is_bbb}" = "xenable" ] ; then
      if [ -e /sys/class/leds/beaglebone\:green\:usr0/trigger ] ; then
        echo default-on > /sys/class/leds/beaglebone\:green\:usr0/trigger
        echo default-on > /sys/class/leds/beaglebone\:green\:usr1/trigger
        echo default-on > /sys/class/leds/beaglebone\:green\:usr2/trigger
        echo default-on > /sys/class/leds/beaglebone\:green\:usr3/trigger
      fi
    fi
    mount

    echo_broadcast "eMMC has been flashed: please wait for device to power down."
    echo_broadcast "-----------------------------"

    flush_cache
    #Why is /sbin/init used ? This not halting the system at all.
    #exec /sbin/init
    exec /sbin/shutdown now
  fi
}

erasing_drive() {
  local drive="${1:?UNKNOWN}"
  echo_broadcast "-----------------------------"
  echo_broadcast "Erasing: ${drive}"
  flush_cache
  dd if=/dev/zero of=${drive} bs=1M count=108
  sync
  dd if=${drive} of=/dev/null bs=1M count=108
  sync
  flush_cache
  echo_broadcast "Erasing: ${drive} complete"
  echo_broadcast "-----------------------------"

}

loading_soc_defaults() {
  local soc_file="/boot/SOC.sh"
  if [ -f ${soc_file} ] ; then
    echo_broadcast "Loading ${soc_file}"
    . ${soc_file}
  else
    echo_broadcast "Could not find ${soc_file}, no defaults are loaded"
  fi
}

_get_ext4_options(){
  #Debian Stretch; mfks.ext4 default to metadata_csum,64bit disable till u-boot works again..
  unset ext4_options
  unset test_mke2fs
  LC_ALL=C mkfs.ext4 -V &> /tmp/mkfs
  test_mkfs=$(cat /tmp/mkfs | grep mke2fs | grep 1.43 || true)
  if [ "x${test_mkfs}" = "x" ] ; then
    ext4_options="-c"
  else
    ext4_options="-c -O ^metadata_csum,^64bit"
  fi

}

partition_drive () {
  erasing_drive ${destination}
  loading_soc_defaults

  _get_ext4_options

  dd_bootloader

  if [ "x${boot_fstype}" = "xfat" ] ; then
    conf_boot_startmb=${conf_boot_startmb:-"4"}
    conf_boot_endmb=${conf_boot_endmb:-"96"}
    sfdisk_fstype=${sfdisk_fstype:-"0xE"}
    boot_label=${boot_label:-"BEAGLEBONE"}
    rootfs_label=${rootfs_label:-"rootfs"}

    echo_broadcast "Formatting: ${destination}"

    sfdisk_options="--force --Linux --in-order --unit M"
    sfdisk_boot_startmb="${conf_boot_startmb}"
    sfdisk_boot_size_mb="${conf_boot_endmb}"
    sfdisk_rootfs_startmb=$(($sfdisk_boot_startmb + $sfdisk_boot_size_mb))

    test_sfdisk=$(LC_ALL=C sfdisk --help | grep -m 1 -e "--in-order" || true)
    if [ "x${test_sfdisk}" = "x" ] ; then
      echo_broadcast "sfdisk: [2.26.x or greater]"
      sfdisk_options="--force"
      sfdisk_boot_startmb="${sfdisk_boot_startmb}M"
      sfdisk_boot_size_mb="${sfdisk_boot_size_mb}M"
      sfdisk_rootfs_startmb="${sfdisk_rootfs_startmb}M"
    fi

    echo_broadcast "sfdisk: [sfdisk ${sfdisk_options} ${destination}]"
    echo_broadcast "sfdisk: [${sfdisk_boot_startmb},${sfdisk_boot_size_mb},${sfdisk_fstype},*]"
    echo_broadcast "sfdisk: [${sfdisk_rootfs_startmb},,,-]"

    LC_ALL=C sfdisk ${sfdisk_options} "${destination}" <<-__EOF__
${sfdisk_boot_startmb},${sfdisk_boot_size_mb},${sfdisk_fstype},*
${sfdisk_rootfs_startmb},,,-
__EOF__

    flush_cache
    format_boot
    format_root
    echo_broadcast "Formatting: ${destination} complete"
    echo_broadcast "-----------------------------"

    copy_boot
    media_rootfs="2"
    copy_rootfs
  else
    conf_boot_startmb=${conf_boot_startmb:-"4"}
    sfdisk_fstype=${sfdisk_fstype:-"L"}
    if [ "x${sfdisk_fstype}" = "x0x83" ] ; then
      sfdisk_fstype="L"
    fi
    boot_label=${boot_label:-"BEAGLEBONE"}
    if [ "x${boot_label}" = "xBOOT" ] ; then
      boot_label="rootfs"
    fi

    echo_broadcast "Formatting: ${destination}"

    sfdisk_options="--force --Linux --in-order --unit M"
    sfdisk_boot_startmb="${conf_boot_startmb}"

    test_sfdisk=$(LC_ALL=C sfdisk --help | grep -m 1 -e "--in-order" || true)
    if [ "x${test_sfdisk}" = "x" ] ; then
      echo_broadcast "sfdisk: [2.26.x or greater]"
      if [ "x${bootrom_gpt}" = "xenable" ] ; then
        sfdisk_options="--force --label gpt"
      else
        sfdisk_options="--force"
      fi
      sfdisk_boot_startmb="${sfdisk_boot_startmb}M"
    fi

    echo_broadcast "sfdisk: [$(LC_ALL=C sfdisk --version)]"
    echo_broadcast "sfdisk: [sfdisk ${sfdisk_options} ${destination}]"
    echo_broadcast "sfdisk: [${sfdisk_boot_startmb},,${sfdisk_fstype},*]"

    LC_ALL=C sfdisk ${sfdisk_options} "${destination}" <<-__EOF__
${sfdisk_boot_startmb},,${sfdisk_fstype},*
__EOF__

    flush_cache
    format_single_root
    echo_broadcast "Formatting: ${destination} complete"
    echo_broadcast "-----------------------------"

    media_rootfs="1"
    copy_rootfs
  fi
}

startup_message(){
  clear
  echo_broadcast "----------------------------------------"
  echo_broadcast "Starting eMMC Flasher from microSD media"
  echo_broadcast "Version: [${version_message}]"
  echo_broadcast "----------------------------------------"
}

activate_cylon_leds() {
  if [ "x${is_bbb}" = "xenable" ] ; then
    cylon_leds & CYLON_PID=$!
  else
    echo "Not activating Cylon LEDs as we are not a BBB compatible device"
  fi
}


