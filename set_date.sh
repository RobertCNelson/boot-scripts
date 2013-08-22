#!/bin/sh -e

if [ -f /etc/timestamp ] ; the
	systemdate=$(/bin/date -u "+%4Y%2m%2d%2H%2M")
	timestamp=$(cat /etc/timestamp)

	if [ ${systemdate} -lt ${timestamp} ] ; then
		/bin/date -u ${timestamp}
	fi
fi

