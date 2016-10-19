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
  reset_leds 'default-on' || true
}

_err_trap() {
  local _ec="$?"
  local _cmd="${BASH_COMMAND:-unknown}"
  _traceback 1
  _showed_traceback=t
  echo "The command ${_cmd} exited with exit code ${_ec}." 1>&2
  teardown_environment
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

__dry_run__(){
  generate_line 80 '!'
  echo_broadcast "! WARNING: ACTIVATED DRY RUN MODE"
  echo_broadcast "! WARNING: THE DRY RUN MODE IS NOT REALLY SAFE"
  echo_broadcast "! WARNING: IT IS GOING TO FAIL WITH IO TO FILES"
  echo_broadcast "! WARNING: USE AT YOUR OWN RISK"
  generate_line 80 '!'
  empty_line

  #This is useful when debugging scripts with potentially destructive commands
  dd() {
    echo "!!! Would run 'dd' with '$@'"
  }
  export -f dd
  reboot() {
    echo "!!! Would run 'reboot' with '$@'"
  }
  export -f reboot
  modprobe() {
    echo "!!! Would run 'modprobe' with '$@'"
  }
  export -f modprobe
  mkfs.vfat() {
    echo "!!! Would run 'mkfs.vfat' with '$@'"
  }
  export -f mkfs.vfat
  mkfs.ext4() {
    echo "!!! Would run 'mkfs.ext4' with '$@'"
  }
  export -f mkfs.ext4
  sfdisk() {
    echo "!!! Would run 'sfdisk' with '$@'"
  }
  export -f sfdisk
  mkdir() {
    echo "!!! Would run 'mkdir' with '$@'"
  }
  export -f mkdir
  rsync() {
    echo "!!! Would run 'rsync' with '$@'"
  }
  export -f rsync
  mount() {
    echo "!!! Would run 'mount' with '$@'"
  }
  export -f mount
  umount() {
    echo "!!! Would run 'umount' with '$@'"
  }
  export -f umount
  cp() {
    echo "!!! Would run 'cp' with '$@'"
  }
  export -f cp
}

prepare_environment() {
  generate_line 80 '='
  echo_broadcast "Prepare environment for flashing"
  start_time=$(date +%s)
  echo_broadcast "Starting at $(date --date="@$start_time")"
  generate_line 40
  echo_broadcast "==> Preparing /tmp"
  mount -t tmpfs tmpfs /tmp
  echo_broadcast "==> Determining root drive"
  find_root_drive
  echo_broadcast "====> Root drive identified at ${root_drive}"
  echo_broadcast "==> Determining boot drive"
  boot_drive="${root_drive%?}1"
  if [ ! "x${boot_drive}" = "x${root_drive}" ] ; then
    echo_broadcast "====> The Boot and Root drives are identified to be different."
    echo_broadcast "====> Mounting ${boot_drive} Read Only over /boot"
    mount ${boot_drive} /boot -o ro
  fi
  echo_broadcast "==> Figuring out Source and Destination devices"
  if [ "x${boot_drive}" = "x/dev/mmcblk0p1" ] ; then
    source="/dev/mmcblk0"
    destination="/dev/mmcblk1"
  elif [ "x${boot_drive}" = "x/dev/mmcblk1p1" ] ; then
    source="/dev/mmcblk1"
    destination="/dev/mmcblk0"
  else
    echo_broadcast "!!! Could not reliably determine Source and Destination"
    echo_broadcast "!!! We need to stop here"
    teardown_environment
    write_failure
    exit 2
  fi
  echo_broadcast "====> Source identified: [${source}]"
  echo_broadcast "====> Destination identified: [${destination}]"
  echo_broadcast "==> Figuring out machine"
  get_device
  echo_broadcast "====> Machine is ${machine}"
  if [ "x${is_bbb}" = "xenable" ] ; then
    echo_broadcast "====> Machine is compatible with BeagleBone Black"
  fi
  generate_line 80 '='
}

teardown_environment() {
  generate_line 80 '='
  echo_broadcast "Tearing Down script environment"
  echo_broadcast "==> Unmounting /tmp"
  flush_cache
  umount /tmp
  if [ ! "x${boot_drive}" = "x${root_drive}" ] ; then
    echo_broadcast "==> Unmounting /boot"
    flush_cache
    umount /boot
  fi
  reset_leds 'none'

  echo_broadcast "==> Force writeback of eMMC buffers by Syncing: ${destination}"
  sync
  generate_line 40
  dd if=${destination} of=/dev/null count=100000
  generate_line 40
  echo_broadcast "===> Syncing: ${destination} complete"
  end_time=$(date +%s)
  echo_broadcast "==> This script took $((${end_time}-${start_time})) seconds to run"
  generate_line 80 '='
}

end_script() {
  empty_line
  if [ -f /boot/debug.txt ] ; then
    echo_broadcast "This script has now completed its task"
    generate_line 40
    echo_broadcast "debug: enabled"
    inf_loop
  else
    reset_leds 'default-on'
    echo_broadcast '==> Displaying mount points'
    generate_line 80
    mount
    generate_line 80
    empty_line
    generate_line 80 '='
    echo_broadcast "eMMC has been flashed: please wait for device to power down."
    generate_line 80 '='

    flush_cache
    #Why is /sbin/init used ? This not halting the system at all.
    #exec /sbin/init
    exec /sbin/shutdown now
  fi
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

empty_line() {
  echo ""
  echo "" > /dev/tty0 || true
}

generate_line() {
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
      echo_broadcast "==> Stopping Cylon LEDs ..."
      kill $CYLON_PID > /dev/null 2>&1
    fi

    if [ -e ${leds_base}0/trigger ] ; then
      echo_broadcast "==> Setting LEDs to ${leds_pattern}"
      echo $leds_pattern > ${leds_base}0/trigger
      echo $leds_pattern > ${leds_base}1/trigger
      echo $leds_pattern > ${leds_base}2/trigger
      echo $leds_pattern > ${leds_base}3/trigger
    fi
  else
    echo_broadcast "!==> We don't know how to reset the leds as we are not a BBB compatible device"
  fi
}

write_failure() {
  echo_broadcast "writing to [${destination}] failed..."

  reset_leds 'heartbeat'

  generate_line 40
  flush_cache
  umount $(dev2dir ${destination}p1) > /dev/null 2>&1 || true
  umount $(dev2dir ${destination}p2) > /dev/null 2>&1 || true
  inf_loop
}

do_we_have_eeprom() {
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
  empty_line
  generate_line 40 '='
  echo_broadcast "Checking for Valid ${device_eeprom} header"

  do_we_have_eeprom

  if [ "x${is_bbb}" = "xenable" ] ; then
    if [ "x${got_eeprom}" = "xtrue" ] ; then
      eeprom_header=$(hexdump -e '8/1 "%c"' ${eeprom} -n 8 | cut -b 6-8)
      if [ "x${eeprom_header}" = "x335" ] ; then
        echo_broadcast "==> Valid ${device_eeprom} header found [${eeprom_header}]"
        generate_line 40 '='
      else
        echo_broadcast "==> Invalid EEPROM header detected"
        if [ -f /opt/scripts/device/bone/${device_eeprom}.dump ] ; then
          if [ ! "x${eeprom_location}" = "x" ] ; then
            echo_broadcast "===> Writing header to EEPROM"
            dd if=/opt/scripts/device/bone/${device_eeprom}.dump of=${eeprom_location}
            sync
            sync
            eeprom_check=$(hexdump -e '8/1 "%c"' ${eeprom} -n 8 | cut -b 6-8)
            echo_broadcast "===> eeprom check: [${eeprom_check}]"
            generate_line 40 '='
            #We have to reboot, as the kernel only loads the eMMC cape
            # with a valid header
            reboot -f

            #We shouldnt hit this...
            exit
          fi
        else
          echo_broadcast "!==> error: no [/opt/scripts/device/bone/${device_eeprom}.dump]"
          generate_line 40 '='
        fi
      fi
    fi
  fi
}

countdown() {
  local from_time=${1:-10}
  while [ $from_time -gt 0 ] ; do
    echo -n "${from_time} "
    sleep 1
    : $((from_time--))
  done
  empty_line
}

check_running_system() {
  empty_line
  generate_line 80 '='
  echo_broadcast "Checking running system"
  echo_broadcast "==> Copying: [${source}] -> [${destination}]"
  echo_broadcast "==> lsblk:"
  generate_line 40
  echo_broadcast "`lsblk || true`"
  generate_line 40
  echo_broadcast "==> df -h | grep rootfs:"
  echo_broadcast "`df -h | grep rootfs || true`"
  generate_line 40

  if [ ! -b "${destination}" ] ; then
    echo_broadcast "!==> Error: [${destination}] does not exist"
    write_failure
  fi

  if [ "x${is_bbb}" = "xenable" ] ; then
    if [ ! -e /sys/class/leds/beaglebone\:green\:usr0/trigger ] ; then
      modprobe leds_gpio || true
      sleep 1
    fi
  fi
  echo_broadcast "==> Giving you time to check..."
  countdown 10
  generate_line 80 '='
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
          1)
            echo 255 > ${BASE}0/brightness
            echo 0   > ${BASE}1/brightness
            STATE=2
            ;;
          2)
            echo 255 > ${BASE}1/brightness
            echo 0   > ${BASE}0/brightness
            STATE=3
            ;;
          3)
            echo 255 > ${BASE}2/brightness
            echo 0   > ${BASE}1/brightness
            STATE=4
            ;;
          4)
            echo 255 > ${BASE}3/brightness
            echo 0   > ${BASE}2/brightness
            STATE=5
            ;;
          5)
            echo 255 > ${BASE}2/brightness
            echo 0   > ${BASE}3/brightness
            STATE=6
            ;;
          6)
            echo 255 > ${BASE}1/brightness
            echo 0   > ${BASE}2/brightness
            STATE=1
            ;;
          *)
            echo 255 > ${BASE}0/brightness
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
  echo_broadcast "==> Figuring out options for SPL U-Boot copy ..."
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
  echo_broadcast "===> Will use : $dd_spl_uboot"
}

_build_uboot_dd_options() {
  echo_broadcast "==> Figuring out options for U-Boot copy ..."
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
  echo_broadcast "===> Will use : $dd_uboot"
}

_dd_bootloader() {
  empty_line
  generate_line 80 '='
  echo_broadcast "Writing bootloader to [${destination}]"
  generate_line 40
  _build_uboot_spl_dd_options
  _build_uboot_dd_options

  echo_broadcast "==> Copying SPL U-Boot with dd if=${dd_spl_uboot_backup} of=${destination} ${dd_spl_uboot}"
  generate_line 60
  dd if=${dd_spl_uboot_backup} of=${destination} ${dd_spl_uboot}
  generate_line 60
  echo_broadcast "==> Copying U-Boot with dd if=${dd_uboot_backup} of=${destination} ${dd_uboot}"
  generate_line 60
  dd if=${dd_uboot_backup} of=${destination} ${dd_uboot}
  generate_line 60
  echo_broadcast "Writing bootloader completed"
  generate_line 80 '='
}

_format_boot() {
  empty_line
  echo_broadcast "==> Formatting boot partition with mkfs.vfat -F 16 ${boot_partition} -n ${boot_label}"
  generate_line 80
  LC_ALL=C mkfs.vfat -c -F 16 ${boot_partition} -n ${boot_label}
  generate_line 80
  echo_broadcast "==> Formatting boot: ${boot_partition} complete"
  flush_cache
}

_format_root() {
  empty_line
  echo_broadcast "==> Formatting rootfs with mkfs.ext4 ${ext4_options} ${rootfs_partition} -L ${rootfs_label}"
  generate_line 80
  empty_line
  LC_ALL=C mkfs.ext4 ${ext4_options} ${rootfs_partition} -L ${rootfs_label}
  generate_line 80
  echo_broadcast "==> Formatting rootfs: ${rootfs_partition} complete"
  flush_cache
}

_copy_boot() {
  empty_line
  generate_line 80 '='
  echo_broadcast "Copying boot: ${source}p1 -> ${boot_partition}"

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
  rsync -aAx --human-readable --info=name0,progress2 /boot/* ${tmp_boot_dir} --exclude={MLO,u-boot.img,uEnv.txt} || write_failure
  flush_cache
  empty_line
  generate_line 80 '='
}

get_device_uuid() {
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

_generate_uEnv() {
  local uEnv_file=${1:-${tmp_rootfs_dir}/boot/uEnv.txt}
  empty_line
  if [ -f $uEnv_file ]; then
    echo_broadcast "==> Found pre-existing uEnv file at ${uEnv_file}. Using it."
    generate_line 80 '*'
    cat $uEnv_file
    generate_line 80 '*'
    empty_line
  else
    echo_broadcast "==> Could not find pre-existing uEnv file at ${uEnv_file}"
    echo_broadcast "===> Generating it from template ..."
    generate_line 40 '*'
    cat > ${uEnv_file} <<__EOF__
#Docs: http://elinux.org/Beagleboard:U-boot_partitioning_layout_2.0

uname_r=$(uname -r)
#uuid=
#dtb=

cmdline=coherent_pool=1M quiet cape_universal=enable

##enable Generic eMMC Flasher:
##make sure, these tools are installed: dosfstools rsync
#cmdline=init=/opt/scripts/tools/eMMC/init-eMMC-flasher-v3.sh

__EOF__
    flush_cache
    generate_line 40 '*'
    empty_line
  fi
  root_uuid=$(get_device_uuid ${rootfs_partition})
  if [ ! -z "${root_uuid}" ] ; then
    echo_broadcast "==> Put root uuid in uEnv.txt"
    sed -i -e 's:^uuid=:#uuid=:g' ${tmp_rootfs_dir}/boot/uEnv.txt
    echo "uuid=${root_uuid}" >> ${tmp_rootfs_dir}/boot/uEnv.txt
  fi
}

get_fstab_id_for_device() {
  local device=${1}
  local device_id=$(get_device_uuid ${device})
  if [ -n ${device_id} ]; then
    echo "UUID=${device_id}"
  else
    echo_debug "Could not find a UUID for ${device}, default to device name"
    # Since the mmc device get reverse depending on how it was booted we need to use source
    echo "${source}p${device:(-1)}"
  fi
}

_generate_fstab() {
  empty_line
  echo_broadcast "==> Generating: /etc/fstab"
  echo "# /etc/fstab: static file system information." > ${tmp_rootfs_dir}/etc/fstab
  echo "#" >> ${tmp_rootfs_dir}/etc/fstab
  if [ "${boot_partition}x" != "${rootfs_partition}x" ] ; then
    boot_fs_id=$(get_fstab_id_for_device ${boot_partition})
    echo "${boot_fs_id} /boot vfat noauto,noatime,nouser,fmask=0022,dmask=0022 0 0" >> ${tmp_rootfs_dir}/etc/fstab
  fi
  root_fs_id=$(get_fstab_id_for_device ${rootfs_partition})
  echo "${root_fs_id}  /  ext4  noatime,errors=remount-ro  0  1" >> ${tmp_rootfs_dir}/etc/fstab
  echo "debugfs  /sys/kernel/debug  debugfs  defaults  0  0" >> ${tmp_rootfs_dir}/etc/fstab
  echo_broadcast "===> /etc/fstab generated"
  generate_line 40 '*'
  cat ${tmp_rootfs_dir}/etc/fstab
  generate_line 40 '*'
  empty_line
}

_copy_rootfs() {
  empty_line
  generate_line 80 '='
  echo_broadcast "Copying: Current rootfs to ${rootfs_partition}"
  generate_line 40
  echo_broadcast "==> rsync: / -> ${tmp_rootfs_dir}"
  generate_line 40
  rsync -aAx --human-readable --info=name0,progress2 /* ${tmp_rootfs_dir} --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found,/lib/modules/*,/uEnv.txt} || write_failure
  flush_cache
  generate_line 40
  echo_broadcast "==> Copying: Kernel modules"
  echo_broadcast "===> Creating directory for modules"
  mkdir -p ${tmp_rootfs_dir}/lib/modules/$(uname -r)/ || true
  echo_broadcast "===> rsync: /lib/modules/$(uname -r)/ -> ${tmp_rootfs_dir}/lib/modules/$(uname -r)/"
  generate_line 40
  rsync -aAx --human-readable --info=name0,progress2 /lib/modules/$(uname -r)/* ${tmp_rootfs_dir}/lib/modules/$(uname -r)/ || write_failure
  flush_cache
  generate_line 40

  echo_broadcast "Copying: Current rootfs to ${rootfs_partition} complete"
  generate_line 80 '='
  empty_line
  generate_line 80 '='
  echo_broadcast "Final System Tweaks:"
  generate_line 40
  if [ -d ${tmp_rootfs_dir}/etc/ssh/ ] ; then
    echo_broadcast "==> Applying SSH Key Regeneration trick"
    #ssh keys will now get regenerated on the next bootup
    touch ${tmp_rootfs_dir}/etc/ssh/ssh.regenerate
    flush_cache
  fi

  _generate_uEnv ${tmp_rootfs_dir}/boot/uEnv.txt

  _generate_fstab

  #FIXME: What about when you boot from a fat partition /boot ?
  echo_broadcast "==> /boot/uEnv.txt: disabling eMMC flasher script"
  sed -i -e 's:'$emmcscript':#'$emmcscript':g' ${tmp_rootfs_dir}/boot/uEnv.txt
  generate_line 40 '*'
  cat ${tmp_rootfs_dir}/boot/uEnv.txt
  generate_line 40 '*'
  flush_cache
}

erasing_drive() {
  local drive="${1:?UNKNOWN}"
  empty_line
  generate_line 40
  echo_broadcast "==> Erasing: ${drive}"
  flush_cache
  generate_line 40
  dd if=/dev/zero of=${drive} bs=1M count=108
  sync
  generate_line 40
  dd if=${drive} of=/dev/null bs=1M count=108
  sync
  generate_line 40
  flush_cache
  echo_broadcast "==> Erasing: ${drive} complete"
  generate_line 40
}

loading_soc_defaults() {
  local soc_file="/boot/SOC.sh"
  empty_line
  if [ -f ${soc_file} ] ; then
    generate_line 40
    echo_broadcast "==> Loading ${soc_file}"
    generate_line 60 '*'
    cat ${soc_file}
    generate_line 60 '*'
    . ${soc_file}
    echo_broadcast "==> Loaded"
  else
    echo_broadcast "!==> Could not find ${soc_file}, no defaults are loaded"
  fi
  empty_line
  generate_line 40
}

get_ext4_options(){
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
  generate_line 80 '!'
  echo_broadcast "WARNING: DEPRECATED PUBLIC INTERFACE"
  echo_broadcast "WARNING: YOU SHOULD USE prepare_drive() INSTEAD"
  echo_broadcast "WARNING: Calling it for you..."
  generate_line 80 '!'
  prepare_drive
}

partition_device() {
  empty_line
  generate_line 80 '='
  echo_broadcast "Partitionning ${destination}"
  generate_line 40
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

    echo_broadcast "==> sfdisk parameters:"
    echo_broadcast "sfdisk: [sfdisk ${sfdisk_options} ${destination}]"
    echo_broadcast "sfdisk: [${sfdisk_boot_startmb},${sfdisk_boot_size_mb},${sfdisk_fstype},*]"
    echo_broadcast "sfdisk: [${sfdisk_rootfs_startmb},,,-]"
    echo_broadcast "==> Partitionning"
    generate_line 60
    LC_ALL=C sfdisk ${sfdisk_options} "${destination}" <<-__EOF__
${sfdisk_boot_startmb},${sfdisk_boot_size_mb},${sfdisk_fstype},*
${sfdisk_rootfs_startmb},,,-
__EOF__
    generate_line 60
    flush_cache
    empty_line
    echo_broadcast "==> Partitionning Completed"
    echo_broadcast "==> Generated Partitions:"
    generate_line 60
    LC_ALL=C sfdisk -l ${destination}
    generate_line 60
    generate_line 80 '='
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

    echo_broadcast "==> sfdisk parameters:"
    echo_broadcast "sfdisk: [$(LC_ALL=C sfdisk --version)]"
    echo_broadcast "sfdisk: [sfdisk ${sfdisk_options} ${destination}]"
    echo_broadcast "sfdisk: [${sfdisk_boot_startmb},,${sfdisk_fstype},*]"
    echo_broadcast "==> Partitionning"
    generate_line 60
    LC_ALL=C sfdisk ${sfdisk_options} "${destination}" <<-__EOF__
${sfdisk_boot_startmb},,${sfdisk_fstype},*
__EOF__
    generate_line 60
    flush_cache
    empty_line
    echo_broadcast "==> Partitionning Completed"
    echo_broadcast "==> Generated Partitions:"
    generate_line 60
    LC_ALL=C sfdisk -l ${destination}
    generate_line 60
    generate_line 80 '='
    boot_partition="${destination}p1"
    rootfs_partition="${boot_partition}"
  fi
  #TODO: Rework this for supporting a more complex partition layout
}

_prepare_future_boot() {
  empty_line
  generate_line 80 '='
  echo_broadcast "Preparing future /boot to receive files"
  generate_line 40
  _format_boot
  tmp_boot_dir=${tmp_boot_dir:-"/tmp/boot"}
  echo_broadcast "==> Creating temporary boot directory (${tmp_boot_dir})"
  mkdir -p ${tmp_boot_dir} || true
  echo_broadcast "==> Mounting ${boot_partition} to ${tmp_boot_dir}"
  mount ${boot_partition} ${tmp_boot_dir} -o sync
  empty_line
  generate_line 80 '='
}

_teardown_future_boot() {
  empty_line
  generate_line 80 '='
  echo_broadcast "Tearing down future boot"
  generate_line 40
  empty_line
  echo_broadcast "==> Unmounting ${tmp_boot_dir}"
  flush_cache
  umount ${tmp_boot_dir} || umount -l ${tmp_boot_dir} || write_failure
  generate_line 80 '='
}

_prepare_future_rootfs() {
  empty_line
  generate_line 80 '='
  echo_broadcast "Preparing future rootfs to receive files"
  generate_line 40
  _format_root
  tmp_rootfs_dir=${tmp_rootfs_dir:-"/tmp/rootfs"}
  echo_broadcast "==> Creating temporary rootfs directory (${tmp_rootfs_dir})"
  mkdir -p ${tmp_rootfs_dir} || true
  echo_broadcast "==> Mounting ${rootfs_partition} to ${tmp_rootfs_dir}"
  mount ${rootfs_partition} ${tmp_rootfs_dir} -o async,noatime
  empty_line
  generate_line 80 '='
}

_teardown_future_rootfs() {
  empty_line
  generate_line 80 '='
  echo_broadcast "Tearing down future rootfs"
  generate_line 40
  empty_line
  echo_broadcast "==> Unmounting ${tmp_rootfs_dir}"
  flush_cache
  umount ${tmp_rootfs_dir} || umount -l ${tmp_rootfs_dir} || write_failure
  generate_line 80 '='
}

prepare_drive() {
  empty_line
  generate_line 80 '='
  echo_broadcast "Preparing drives"
  erasing_drive ${destination}
  loading_soc_defaults

  get_ext4_options

  _dd_bootloader

  boot_partition=
  rootfs_partition=
  partition_device

  if [ "${boot_partition}x" != "${rootfs_partition}x" ] ; then
    tmp_boot_dir="/tmp/boot"
    _prepare_future_boot
    _copy_boot
    _teardown_future_boot

    tmp_rootfs_dir="/tmp/rootfs"
    _prepare_future_rootfs
    media_rootfs="2"
    _copy_rootfs
    _teardown_future_rootfs
  else
    rootfs_label=${boot_label}
    tmp_rootfs_dir="/tmp/rootfs"
    _prepare_future_rootfs
    media_rootfs="1"
    _copy_rootfs
    _teardown_future_rootfs
  fi
  teardown_environment
  end_script
}

startup_message(){
  clear
  generate_line 80 '='
  echo_broadcast "Starting eMMC Flasher from microSD media"
  echo_broadcast "Version: [${version_message}]"
  generate_line 80 '='
  empty_line
}

activate_cylon_leds() {
  if [ "x${is_bbb}" = "xenable" ] ; then
    cylon_leds & CYLON_PID=$!
  else
    echo "Not activating Cylon LEDs as we are not a BBB compatible device"
  fi
}

