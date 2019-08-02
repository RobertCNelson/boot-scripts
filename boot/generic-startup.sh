#!/bin/sh -e

#eMMC flasher just exited single user mode via: [exec /sbin/init]
#as we can't shudown properly in single user mode..
unset are_we_flasher
are_we_flasher=$(grep init-eMMC-flasher /proc/cmdline || true)
if [ ! "x${are_we_flasher}" = "x" ] ; then
	systemctl poweroff || halt
	exit
fi

#Regenerate ssh host keys
if [ -f /etc/ssh/ssh.regenerate ] ; then
	echo "generic-board-startup: regenerating ssh keys"
	systemctl stop sshd
	rm -rf /etc/ssh/ssh_host_* || true

	if [ -e /dev/hwrng ] ; then
		# Mix in the output of the HWRNG to the kernel before generating ssh keys
		dd if=/dev/hwrng of=/dev/urandom count=1 bs=4096 2>/dev/null
		echo "generic-board-startup: if=/dev/hwrng of=/dev/urandom count=1 bs=4096"
	else
		echo "generic-board-startup: WARNING /dev/hwrng wasn't available"
	fi

	dpkg-reconfigure openssh-server

	# while we're at it, make sure we have unique machine IDs as well
	rm -f /var/lib/dbus/machine-id || true
	rm -f /etc/machine-id || true
	dbus-uuidgen --ensure
	systemd-machine-id-setup

	sync
	if [ -s /etc/ssh/ssh_host_ed25519_key.pub ] ; then
		rm -f /etc/ssh/ssh.regenerate || true
		sync
		systemctl start sshd
	fi
fi

if [ -f /boot/efi/EFI/efi.gen ] ; then
	if [ -f /usr/sbin/grub-install ] ; then
		echo "grub-install --efi-directory=/boot/efi/ --target=arm-efi --no-nvram"
		grub-install --efi-directory=/boot/efi/ --target=arm-efi --no-nvram
		echo "update-grub"
		update-grub
		sync
	fi
	rm -rf /boot/efi/EFI/efi.gen || true
	sync
fi

#Resize drive when requested
if [ -f /resizerootfs ] ; then
	echo "generic-board-startup: resizerootfs"

	unset is_btrfs
	is_btrfs=$(cat /proc/cmdline | grep btrfs || true)

	if [ "x${is_btrfs}" = "x" ] ; then
		drive=$(cat /resizerootfs)
		if [ ! "x${drive}" = "x" ] ; then
			echo "generic-board-startup: "
			if [ "x${drive}" = "x/dev/mmcblk0" ] || [ "x${drive}" = "x/dev/mmcblk1" ] ; then
				echo "generic-board-startup: resize2fs ${drive}p2"
				resize2fs ${drive}p2 >/var/log/resize.log 2>&1 || true
			else
				echo "generic-board-startup: resize2fs ${drive}"
				resize2fs ${drive} >/var/log/resize.log 2>&1 || true
			fi
		fi
	else
		echo "generic-board-startup: btrfs filesystem resize max /"
		btrfs filesystem resize max / >/var/log/resize.log 2>&1 || true
	fi

	rm -rf /resizerootfs || true
	sync
fi

if [ -d /sys/class/gpio/ ] ; then
	/bin/chgrp -R gpio /sys/class/gpio/ || true
	/bin/chmod -R g=u /sys/class/gpio/ || true

	/bin/chgrp -R gpio /dev/gpiochip* || true
	/bin/chmod -R g=u /dev/gpiochip* || true
fi

if [ -d /sys/class/leds ] ; then
	/bin/chgrp -R gpio /sys/class/leds/ || true
	/bin/chmod -R g=u /sys/class/leds/ || true

	if [ -d /sys/devices/platform/leds/leds/ ] ; then
		/bin/chgrp -R gpio /sys/devices/platform/leds/leds/ || true
		/bin/chmod -R g=u  /sys/devices/platform/leds/leds/ || true
	fi
fi

if [ -f /proc/device-tree/model ] ; then
	board=$(cat /proc/device-tree/model | sed "s/ /_/g")
	echo "generic-board-startup: [model=${board}]"

	case "${board}" in
	TI_AM335x*|Arrow_BeagleBone_Black_Industrial|SanCloud_BeagleBone_Enhanced|Octavo_Systems*)
		script="am335x_evm.sh"
		;;
	TI_AM5728*)
		script="beagle_x15.sh"
		;;
	TI_OMAP3_Beagle*)
		script="omap3_beagle.sh"
		;;
	TI_OMAP5_uEVM_board)
		script="omap5_uevm.sh"
		;;
	BeagleBoard.org_BeagleBone_AI)
		script="bbai.sh"
		;;
	*)
		script="generic.sh"
		;;
	esac

	if [ -f "/opt/scripts/boot/${script}" ] ; then
		echo "generic-board-startup: [startup script=/opt/scripts/boot/${script}]"
		/bin/sh /opt/scripts/boot/${script}
	fi
fi
