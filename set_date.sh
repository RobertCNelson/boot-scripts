#!/bin/sh -e

if [ -f /etc/timestamp ] ; then
	systemdate=$(/bin/date --utc "+%4Y%2m%2d%2H%2M")
	timestamp=$(cat /etc/timestamp)

	if [ ${timestamp} -gt ${systemdate} ] ; then
		/bin/date -u ${timestamp}
	fi
fi

