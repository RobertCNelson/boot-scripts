#!/bin/sh -e

if [ -f /etc/timestamp ] ; then
	systemdate=$(/bin/date --utc "+%4Y%2m%2d%2H%2M")
	timestamp=$(cat /etc/timestamp)

	if [ ${timestamp} -gt ${systemdate} ] ; then
		year=$(cat /etc/timestamp | cut -b 1-4)
		month=$(cat /etc/timestamp | cut -b 5-6)
		day=$(cat /etc/timestamp | cut -b 7-8)
		hour=$(cat /etc/timestamp | cut -b 9-10)
		min=$(cat /etc/timestamp | cut -b 11-12)

		#/bin/date --utc -s "10/08/2008 11:37:23"
		/bin/date --utc -s "${month}/${day}/${year} ${hour}:${min}:00"
	fi
fi

