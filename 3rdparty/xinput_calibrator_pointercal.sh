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

#Device:
whitelist=`$BINARY --list | sed 's/ /_/g' | awk -F "\"" '{print $2}' | grep EP0790M09 || true`

if [ ! "x${whitelist}" = "x" ] ; then
	CALFILE="/etc/pointercal.xinput.EP0790M09"
	device_id=`$BINARY --list | grep EP0790M09 | sed 's/ /\n/g' | grep id | awk -F 'id=' '{print #2}'`

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
#
