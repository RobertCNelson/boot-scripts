#!/bin/bash -e
#
# This script is alibrary of common functions used by the other scripts in the current directory
# It is meant to be sourced by the other scripts, NOT executed.
# Source it like this:
# source $(dirname "$0")/functions.sh

version_message="1.20161005: sfdisk: actually calculate the start of 2nd/3rd partitions..."
emmcscript="cmdline=init=/opt/scripts/tools/eMMC/$(basename $0)"

set -o errtrace

trap _exit_trap EXIT
trap _err_trap ERR
_showed_traceback=f

_exit_trap() {
  local _ec="$?"
  if [[ $_ec != 0 && "${_showed_traceback}" != t ]]; then
    _traceback 1
  fi
}

_err_trap() {
  local _ec="$?"
  local _cmd="${BASH_COMMAND:-unknown}"
  _traceback 1
  _showed_traceback=t
  echo "The command ${_cmd} exited with exit code ${_ec}." 1>&2
}

_traceback() {
  # Hide the _traceback() call.
  local -i start=$(( ${1:-0} + 1 ))
  local -i end=${#BASH_SOURCE[@]}
  local -i i=0
  local -i j=0

  echo "Traceback (last called is first):" 1>&2
  for ((i=${start}; i < ${end}; i++)); do
    j=$(( $i - 1 ))
    local function="${FUNCNAME[$i]}"
    local file="${BASH_SOURCE[$i]}"
    local line="${BASH_LINENO[$j]}"
    echo "     ${function}() in ${file}:${line}" 1>&2
  done
}

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

flush_cache() {
  sync
  blockdev --flushbufs ${destination}
}

broadcast() {
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

echo_debug() {
  local _message="$1"
  if [ "x${_message}" != "x" ] ; then
    echo "${_message}" >&2
    echo "${_message}" >&2 > /dev/tty0 || true
  fi
}

_generate_line() {
  local line_length=${1:-80}
  local line_char=${2:-\-}
  local line=$(printf "%${line_length}s\n" | tr ' ' \\$line_char)
  echo_broadcast "${line}"
}

inf_loop() {
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
dev2dir() {
  grep -m 1 '^$1 ' /proc/mounts | while read LINE ; do set -- $LINE ; echo $2 ; done
}

get_device() {
  is_bbb="enable"
  machine=$(cat /proc/device-tree/model | sed "s/ /_/g")

  case "${machine}" in
    TI_AM5728_BeagleBoard*)
      unset is_bbb
      ;;
  esac
}

reset_leds() {
  local leds_pattern=${1:-heartbeat}
  local leds_base=/sys/class/leds/beaglebone\:green\:usr
  if [ "x${is_bbb}" = "xenable" ] ; then
    if [ -e /proc/$CYLON_PID ]; then
      echo_broadcast "Stopping Cylon LEDs ..."
      kill $CYLON_PID > /dev/null 2>&1
    fi

    if [ -e ${leds_base}0/trigger ] ; then
      echo_broadcast "Setting LEDs to ${leds_pattern}"
      echo $leds_pattern > ${leds_base}0/trigger
      echo $leds_pattern > ${leds_base}1/trigger
      echo $leds_pattern > ${leds_base}2/trigger
      echo $leds_pattern > ${leds_base}3/trigger
    fi
  else
    echo_broadcast "We don't know how to reset the leds as we are not a BBB compatible device"
  fi
}

write_failure() {
  echo_broadcast "writing to [${destination}] failed..."

  reset_leds 'heartbeat'

  _generate_line 40
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

check_eeprom() {
  echo_broadcast "Checking for Valid ${device_eeprom} header"

  _do_we_have_eeprom

  if [ "x${is_bbb}" = "xenable" ] ; then
    if [ "x${got_eeprom}" = "xtrue" ] ; then
      eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -n 8 | cut -b 6-8)
      if [ "x${eeprom_header}" = "x335" ] ; then
        echo_broadcast "Valid ${device_eeprom} header found [${eeprom_header}]"
        _generate_line 40
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

check_running_system() {
  echo_broadcast "copying: [${source}] -> [${destination}]"
  echo_broadcast "lsblk:"
  echo_broadcast "`lsblk || true`"
  _generate_line 40
  echo_broadcast "df -h | grep rootfs:"
  echo_broadcast "`df -h | grep rootfs || true`"
  _generate_line 40

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

cylon_leds() {
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

dd_bootloader() {
  echo_broadcast ""
  _generate_line 80 '='
  echo_broadcast "Writing bootloader to [${destination}]"

  _build_uboot_spl_dd_options
  _build_uboot_dd_options

  _generate_line 80
  echo_broadcast "Copying SPL U-Boot with dd if=${dd_spl_uboot_backup} of=${destination} ${dd_spl_uboot}"
  dd if=${dd_spl_uboot_backup} of=${destination} ${dd_spl_uboot}
  _generate_line 80
  echo_broadcast "Copying U-Boot with dd if=${dd_uboot_backup} of=${destination} ${dd_uboot}"
  dd if=${dd_uboot_backup} of=${destination} ${dd_uboot}
  echo_broadcast ""
  echo_broadcast "Writing BootLoader completed"
  _generate_line 80 '='
  echo_broadcast ""
}

format_boot() {
  echo_broadcast ""
  _generate_line 80 '='
  echo_broadcast "Formatting boot partition with mkfs.vfat -F 16 ${boot_partition} -n ${boot_label}"
  LC_ALL=C mkfs.vfat -c -F 16 ${boot_partition} -n ${boot_label}
  echo_broadcast ""
  echo_broadcast "Formatting boot: ${boot_partition} complete"
  _generate_line 80 '='
  echo_broadcast ""
  flush_cache
}

format_root() {
  echo_broadcast ""
  _generate_line 80 '='
  echo_broadcast "Formatting rootfs with mkfs.ext4 ${ext4_options} ${rootfs_partition} -L ${rootfs_label}"
  LC_ALL=C mkfs.ext4 ${ext4_options} ${rootfs_partition} -L ${rootfs_label}
  echo_broadcast ""
  echo_broadcast "Formatting rootfs: ${rootfs_partition} complete"
  _generate_line 80 '='
  echo_broadcast ""
  flush_cache
}

format_single_root() {
  rootfs_label=${boot_label}
  format_root
}

copy_boot() {
  #FIXME: Something is fishy about this function
  local tmp_boot_dir="/tmp/boot"
  echo_broadcast ""
  _generate_line 80
  echo_broadcast "Copying: ${source}p1 -> ${boot_partition}"
  echo_broadcast "==> Creating temporary boot directory (${tmp_boot_dir})"
  mkdir -p ${tmp_boot_dir} || true
  echo_broadcast "==> Mounting ${boot_partition} to ${tmp_boot_dir}"
  mount ${boot_partition} ${tmp_boot_dir} -o sync

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
  rsync -aAxz --human-readable --info=name0,progress2 /boot/* ${tmp_boot_dir} --exclude={MLO,u-boot.img,uEnv.txt} || write_failure
  flush_cache

  echo_broadcast "==> Unmounting ${tmp_boot_dir}"
  umount ${tmp_boot_dir} || umount -l ${tmp_boot_dir} || write_failure
  flush_cache
  #FIXME: When was this mounted ? Why is it going to be unmounted ?
  umount /boot/uboot || umount -l /boot/uboot || true
  _generate_line 80
}

_get_device_uuid() {
  local device=${1}
  unset device_uuid
  device_uuid=$(/sbin/blkid /dev/null -s UUID -o value ${device})
  if [ ! -z "${device_uuid}" ] ; then
    echo_debug "Device UUID should be: ${device_uuid}"
    echo $device_uuid
  else
    echo_debug "Could not get a proper UUID for $device. Try with another ID"
  fi
}

generate_uEnv() {
  local uEnv_file=${1:-${tmp_rootfs_dir}/boot/uEnv.txt}
  if [ -f $uEnv_file ]; then
    echo_broadcast "Found pre-existing uEnv file at ${uEnv_file}. Using it."
    _generate_line 80
    cat $uEnv_file
    _generate_line 80
  else
    echo_broadcast "Could not find pre-existing uEnv file at ${uEnv_file}"
    echo_broadcast "Generating it from template ..."
    _generate_line 40
    cat > ${uEnv_file} <<__EOF__
#Docs: http://elinux.org/Beagleboard:U-boot_partitioning_layout_2.0

uname_r=$(uname -r)
#uuid=
#dtb=

##BeagleBone Black/Green dtb's for v4.1.x (BeagleBone White just works..)

##BeagleBone Black: HDMI (Audio/Video) disabled:
#dtb=am335x-boneblack-emmc-overlay.dtb

##BeagleBone Black: eMMC disabled:
#dtb=am335x-boneblack-hdmi-overlay.dtb

##BeagleBone Black: HDMI Audio/eMMC disabled:
#dtb=am335x-boneblack-nhdmi-overlay.dtb

##BeagleBone Black: HDMI (Audio/Video)/eMMC disabled:
#dtb=am335x-boneblack-overlay.dtb

##BeagleBone Black: wl1835
#dtb=am335x-boneblack-wl1835mod.dtb

##BeagleBone Green: eMMC disabled
#dtb=am335x-bonegreen-overlay.dtb

cmdline=coherent_pool=1M quiet cape_universal=enable

#In the event of edid real failures, uncomment this next line:
#cmdline=coherent_pool=1M quiet cape_universal=enable video=HDMI-A-1:1024x768@60e

##Example v3.8.x
#cape_disable=capemgr.disable_partno=
#cape_enable=capemgr.enable_partno=

##Example v4.1.x
#cape_disable=bone_capemgr.disable_partno=
#cape_enable=bone_capemgr.enable_partno=

##enable Generic eMMC Flasher:
##make sure, these tools are installed: dosfstools rsync
#cmdline=init=/opt/scripts/tools/eMMC/init-eMMC-flasher-v3.sh

__EOF__
  flush_cache
  _generate_line 40
  fi
  root_uuid=$(_get_device_uuid ${rootfs_partition})
  if [ ! -z "${root_uuid}" ] ; then
    echo_broadcast "==> Put root uuid in uEnv.txt"
    sed -i -e 's:^uuid=:#uuid=:g' ${tmp_rootfs_dir}/boot/uEnv.txt
    echo "uuid=${root_uuid}" >> ${tmp_rootfs_dir}/boot/uEnv.txt
  fi

}

_get_fstab_id_for_device() {
  local device=${1}
  local device_id=$(_get_device_uuid ${device})
  if [ -n ${device_id} ]; then
    echo "UUID=${device_id}"
  else
    echo_debug "Could not find a UUID for ${device}, default to device name"
    # Since the mmc device get reverse depending on how it was booted we need to use source
    echo "${source}p${device:(-1)}"
  fi
}

_generate_fstab() {
  echo_broadcast "Generating: /etc/fstab"
  echo "# /etc/fstab: static file system information." > ${tmp_rootfs_dir}/etc/fstab
  echo "#" >> ${tmp_rootfs_dir}/etc/fstab
  if [ "${boot_partition}x" != "${rootfs_partition}x" ] ; then
    boot_fs_id=$(_get_fstab_id_for_device ${boot_partition})
    echo "${boot_fs_id} /boot vfat noauto,noatime,nouser,fmask=0022,dmask=0022 0 0" >> ${tmp_rootfs_dir}/etc/fstab
  fi
  root_fs_id=$(_get_fstab_id_for_device ${rootfs_partition})
  echo "${root_fs_id}  /  ext4  noatime,errors=remount-ro  0  1" >> ${tmp_rootfs_dir}/etc/fstab
  echo "debugfs  /sys/kernel/debug  debugfs  defaults  0  0" >> ${tmp_rootfs_dir}/etc/fstab
  echo_broadcast "/etc/fstab generated"
  _generate_line 40
  cat ${tmp_rootfs_dir}/etc/fstab
  _generate_line 40
}

copy_rootfs() {
  local tmp_rootfs_dir="/tmp/rootfs"
  echo_broadcast ""
  _generate_line 80
  echo_broadcast "Copying: Current rootfs to ${rootfs_partition}"
  echo_broadcast "==> Creating temporary rootfs directory (${tmp_rootfs_dir})"
  mkdir -p ${tmp_rootfs_dir} || true
  echo_broadcast "==> Mounting ${rootfs_partition} to ${tmp_rootfs_dir}"
  mount ${rootfs_partition} ${tmp_rootfs_dir} -o async,noatime

  echo_broadcast "==> rsync: / -> ${tmp_rootfs_dir}"
  rsync -aAxz --human-readable --info=name0,progress2 /* ${tmp_rootfs_dir} --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found,/lib/modules/*,/uEnv.txt} || write_failure
  flush_cache

  echo_broadcast "==> Copying: Kernel modules"
  echo_broadcast "===> Creating directory for modules"
  mkdir -p ${tmp_rootfs_dir}/lib/modules/$(uname -r)/ || true
  echo_broadcast "===> rsync: /lib/modules/$(uname -r)/ -> ${tmp_rootfs_dir}/lib/modules/$(uname -r)/"
  rsync -aAxz --human-readable --info=name0,progress2 /lib/modules/$(uname -r)/* ${tmp_rootfs_dir}/lib/modules/$(uname -r)/ || write_failure
  flush_cache

  echo_broadcast "Copying: Current rootfs to ${rootfs_partition} complete"

  echo_broadcast "Final System Tweaks:"
  if [ -d ${tmp_rootfs_dir}/etc/ssh/ ] ; then
    echo_broadcast "==> Applying SSH Key Regeneration trick"
    #ssh keys will now get regenerated on the next bootup
    touch ${tmp_rootfs_dir}/etc/ssh/ssh.regenerate
    flush_cache
  fi

  generate_uEnv ${tmp_rootfs_dir}/boot/uEnv.txt

  _generate_fstab

  #FIXME: What about when you boot from a fat partition /boot ?
  echo_broadcast "==> /boot/uEnv.txt: disabling eMMC flasher script"
  sed -i -e 's:'$emmcscript':#'$emmcscript':g' ${tmp_rootfs_dir}/boot/uEnv.txt
  cat ${tmp_rootfs_dir}/boot/uEnv.txt
  flush_cache

  echo_broadcast "==> Unmounting ${tmp_rootfs_dir}"
  umount ${tmp_rootfs_dir} || umount -l ${tmp_rootfs_dir} || write_failure

  reset_leds 'none'

  echo_broadcast "==> Syncing: ${destination}"
  #https://github.com/beagleboard/meta-beagleboard/blob/master/contrib/bone-flash-tool/emmc.sh#L158-L159
  # force writeback of eMMC buffers
  sync
  dd if=${destination} of=/dev/null count=100000
  echo_broadcast "Syncing: ${destination} complete"
  _generate_line 80

  if [ -f /boot/debug.txt ] ; then
    echo_broadcast "This script has now completed its task"
    _generate_line 40
    echo_broadcast "debug: enabled"
    inf_loop
  else
    #FIXME: Why are we unmounting the host /tmp ?
    umount /tmp || umount -l /tmp
    reset_leds 'default-on'
    echo_broadcast 'Displaying mount points'
    _generate_line 80
    mount
    _generate_line 80 '='
    echo_broadcast "eMMC has been flashed: please wait for device to power down."
    _generate_line 80 '='

    flush_cache
    #Why is /sbin/init used ? This not halting the system at all.
    #exec /sbin/init
    exec /sbin/shutdown now
  fi
}

erasing_drive() {
  local drive="${1:?UNKNOWN}"
  _generate_line 40
  echo_broadcast "Erasing: ${drive}"
  flush_cache
  dd if=/dev/zero of=${drive} bs=1M count=108
  sync
  dd if=${drive} of=/dev/null bs=1M count=108
  sync
  flush_cache
  echo_broadcast "Erasing: ${drive} complete"
  _generate_line 40
}

loading_soc_defaults() {
  local soc_file="/boot/SOC.sh"
  if [ -f ${soc_file} ] ; then
    echo_broadcast "Loading ${soc_file}"
    _generate_line 60 '*'
    cat ${soc_file}
    _generate_line 60 '*'
    . ${soc_file}
    echo_broadcast "Loaded"
  else
    echo_broadcast "Could not find ${soc_file}, no defaults are loaded"
  fi
}

_get_ext4_options(){
  #Debian Stretch; mfks.ext4 default to metadata_csum,64bit disable till u-boot works again..
  unset ext4_options
  unset test_mkfs
  LC_ALL=C mkfs.ext4 -V &> /tmp/mkfs
  test_mkfs=$(cat /tmp/mkfs | grep mke2fs | grep 1.43 || true)
  if [ "x${test_mkfs}" = "x" ] ; then
    ext4_options="-c"
  else
    ext4_options="-c -O ^metadata_csum,^64bit"
  fi
}

partition_drive() {
  _generate_line 80 '!'
  echo_broadcast "WARNING: DEPRECATED PUBLIC INTERFACE"
  echo_broadcast "WARNING: YOU SHOULD USE prepare_drive() instead"
  echo_broadcast "WARNING: Calling it for you..."
  _generate_line 80 '!'
  prepare_drive
}

partition_device() {
  echo_broadcast ""
  _generate_line 80 '='
  echo_broadcast "Partitionning ${destination}"

  if [ "x${boot_fstype}" = "xfat" ] ; then
    conf_boot_startmb=${conf_boot_startmb:-"4"}
    conf_boot_endmb=${conf_boot_endmb:-"96"}
    sfdisk_fstype=${sfdisk_fstype:-"0xE"}
    boot_label=${boot_label:-"BEAGLEBONE"}
    rootfs_label=${rootfs_label:-"rootfs"}

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
    echo_broadcast "Partitionning Completed"
    _generate_line 40
    echo_broadcast "Generated Partitions:"
    LC_ALL=C sfdisk -l ${destination}
    _generate_line 80 '='
    echo_broadcast ""
    boot_partition="${destination}p1"
    rootfs_partition="${destination}p2"
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
    echo_broadcast "Partitionning Completed"
    _generate_line 40
    echo_broadcast "Generated Partitions:"
    LC_ALL=C sfdisk -l ${destination}
    _generate_line 80 '='
    echo_broadcast ""
    boot_partition="${destination}p1"
    rootfs_partition="${boot_partition}"
  fi
  #TODO: Rework this for supporting a more complex partition layout
}

prepare_drive() {
  erasing_drive ${destination}
  loading_soc_defaults

  _get_ext4_options

  dd_bootloader

  boot_partition=
  rootfs_partition=
  partition_device

  if [ "${boot_partition}x" != "${rootfs_partition}x" ] ; then
    format_boot
    format_root

    copy_boot
    media_rootfs="2"
    copy_rootfs
  else
    format_single_root

    media_rootfs="1"
    copy_rootfs
  fi
}

startup_message(){
  clear
  _generate_line 80 '='
  echo_broadcast "Starting eMMC Flasher from microSD media"
  echo_broadcast "Version: [${version_message}]"
  _generate_line 80 '='
  echo_broadcast ""
}

activate_cylon_leds() {
  if [ "x${is_bbb}" = "xenable" ] ; then
    cylon_leds & CYLON_PID=$!
  else
    echo "Not activating Cylon LEDs as we are not a BBB compatible device"
  fi
}

