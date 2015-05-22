#!/bin/sh -e

#Regenerate ssh host keys
if [ -f /etc/ssh/ssh.regenerate ] ; then
	echo "generic-board-startup: regnerating ssh keys"
	systemctl stop sshd
	rm -rf /etc/ssh/ssh_host_* || true
	dpkg-reconfigure openssh-server
	sync
	if [ -s /etc/ssh/ssh_host_ed25519_key.pub ] ; then
		rm -f /etc/ssh/ssh.regenerate || true
		sync
		systemctl start sshd
	fi
fi

#Resize drive when requested
if [ -f /resizerootfs ] ; then
	echo "generic-board-startup: resizerootfs"
	drive=$(cat /resizerootfs)
	if [ ! "x${drive}" = "x" ] ; then
		if [ "x${drive}" = "x/dev/mmcblk0" ] || [ "x${drive}" = "x/dev/mmcblk1" ] ; then
			resize2fs ${drive}p2 >/var/log/resize.log 2>&1 || true
		else
			resize2fs ${drive} >/var/log/resize.log 2>&1 || true
		fi
	fi
	rm -rf /resizerootfs || true
	sync
fi

if [ -f /proc/device-tree/model ] ; then
	board=$(cat /proc/device-tree/model | sed "s/ /_/g")
	echo "generic-board-startup: [model=${board}]"

	case "${board}" in
	TI_AM335x_BeagleBone|TI_AM335x_BeagleBone_Black|TI_AM335x_Arduino_Tre)
		script="am335x_evm.sh"
		;;
	TI_AM5728_BeagleBoard-X15)
		script="beagle_x15.sh"
		;;
	TI_OMAP3_BeagleBoard|TI_OMAP3_BeagleBoard_xM)
		script="omap3_beagle.sh"
		;;
	TI_OMAP5_uEVM_board)
		script="omap5_uevm.sh"
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
