#!/bin/sh
# script to make the changes permanent (xinput is called with every Xorg start)
#
# can be used from Xsession.d
# script needs tee and sed (busybox variants are enough)
#
# original script: Martin Jansa <Martin.Jansa@gmail.com>, 2010-01-31
# updated by Tias Guns <tias@ulyssis.org>, 2010-02-15
# updated by Koen Kooi <koen@dominion.thruhere.net>, 2012-02-28

PATH="/usr/bin:$PATH"

BINARY="xinput_calibrator"
CALFILE="/etc/pointercal.xinput"
LOGFILE="/var/log/xinput_calibrator.pointercal.log"

unset detected_capes
detected_capes=$(cat /proc/cmdline | sed 's/ /\n/g' | grep uboot_detected_capes= || true)
if [ ! "x${detected_capes}" = "x" ] ; then
	unset scan_ts
	got_4D4R=$(echo ${detected_capes} | grep BB-BONE-4D4R-01 || true)
	if [ ! "x${got_4D4R}" = "x" ] ; then
		echo "xinput_calibrator: found: 4D4R touchscreen (ar1021 I2C Touchscreen)"
		scan_ts="ar1021"
	fi
	if [ ! "x${scan_ts}" = "x" ] ; then
		CALFILE="/etc/pointercal.xinput.${scan_ts}"
		echo "xinput_calibrator: xinput_calibrator --list | grep ${scan_ts}"
		device_id=`$BINARY --list | grep ${scan_ts} | sed 's/ /\n/g' | grep id | awk -F "id=" '{print $2}'`
		if [ "x${device_id}" = "x" ] ; then
			echo "xinput_calibrator: too fast... sleep 5..."
			sleep 5
			device_id=`$BINARY --list | grep ${scan_ts} | sed 's/ /\n/g' | grep id | awk -F "id=" '{print $2}'`
		fi

		if [ ! "x${device_id}" = "x" ] ; then
			echo "xinput_calibrator: using: xinput: id=${device_id}"

			if [ -e $CALFILE ] ; then
			  if grep replace $CALFILE ; then
			    echo "Empty calibration file found, removing it"
			    rm $CALFILE
			  else
			    echo "Using calibration data stored in $CALFILE"
			    . $CALFILE && exit 0
			  fi
			fi

			echo "xinput_calibrator: xinput_calibrator --device ${device_id} --output-type xinput -v"
			CALDATA=`$BINARY --device ${device_id} --output-type xinput -v | tee $LOGFILE | grep '    xinput set' | sed 's/^    //g; s/$/;/g'`
			if [ ! -z "$CALDATA" ] ; then
			  echo $CALDATA > $CALFILE
			  echo "Calibration data stored in $CALFILE (log in $LOGFILE)"
			fi
		else
			echo "xinput_calibrator: failed to get device_id..."
		fi
	fi

###FIXME: 3.8.x do all this old crap...
else
	#Device:
	whitelist=`$BINARY --list | sed 's/ /_/g' | awk -F "\"" '{print $2}' | grep EP0790M09 || true`

	if [ ! "x${whitelist}" = "x" ] ; then
		CALFILE="/etc/pointercal.xinput.EP0790M09"
		device_id=`$BINARY --list | grep EP0790M09 | sed 's/ /\n/g' | grep id | awk -F "id=" '{print $2}'`

		if [ -e $CALFILE ] ; then
		  if grep replace $CALFILE ; then
		    echo "Empty calibration file found, removing it"
		    rm $CALFILE
		  else
		    echo "Using calibration data stored in $CALFILE"
		    . $CALFILE && exit 0
		  fi
		fi

		CALDATA=`$BINARY --device ${device_id} --output-type xinput -v | tee $LOGFILE | grep '    xinput set' | sed 's/^    //g; s/$/;/g'`
		if [ ! -z "$CALDATA" ] ; then
		  echo $CALDATA > $CALFILE
		  echo "Calibration data stored in $CALFILE (log in $LOGFILE)"
		fi
	else
		if [ -e $CALFILE ] ; then
		  if grep replace $CALFILE ; then
		    echo "Empty calibration file found, removing it"
		    rm $CALFILE
		  else
		    echo "Using calibration data stored in $CALFILE"
		    . $CALFILE && exit 0
		  fi
		fi

		##BlackList:
		#Logitech USB Keyboard
		unset blacklist
		blacklist=`$BINARY --list | sed 's/ /_/g' | awk -F "\"" '{print $2}' || true`
		if [ "x${blacklist}" = "xLogitech_USB_Keyboard" ] ; then
			exit 0
		fi

		CALDATA=`$BINARY --output-type xinput -v | tee $LOGFILE | grep '    xinput set' | sed 's/^    //g; s/$/;/g'`
		if [ ! -z "$CALDATA" ] ; then
		  echo $CALDATA > $CALFILE
		  echo "Calibration data stored in $CALFILE (log in $LOGFILE)"
		fi
	fi
fi
#
