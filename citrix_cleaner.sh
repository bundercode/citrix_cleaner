#!/bin/bash

#
# This script will run if disk usage is above 90%
#  to change cutoff value, change the THRESHOLD variable
#  ie. THRESHOLD=80 means script will run if disk usage is above 80%
#
# You can also use the -f flag to force the script to run,
#  ignoring the THRESHOLD variable
#

# disk usage threshold before cleanup is run
THRESHOLD=90

if [ "$1" == "-f" ]
then
	THRESHOLD=0
fi

USAGE=`df -h | grep "/$" | head -n 1 | awk {' print $5 '} | sed -n -e "s/%//p"`
echo "Disk usage before cleanup: ${USAGE}%"

if [ $USAGE -gt $THRESHOLD ]
then
	# if current month is January
	if [ `date +%m` -eq 01 ]
	then
		DATE=`date +%Y12%d%k%M`		# set date to December
	else
		# if current day is past the 28th
		if [ `date +%d` -gt 28 ]
		then
			DATE=`date +%Y%m28%k%M`		# set current date to 28th
			DATE=`expr $DATE - 1000000`	# subract one month
		else
			DATE=`date +%Y%m%d%k%M`		# get current date and time
			DATE=`expr $DATE - 1000000`	# subract one month
		fi
	fi
	
	# create file for date comparison
	touch -t $DATE /tmp/comparefile

	# remove log files
	find /var/log -name *.gz -type f ! -newer /tmp/comparefile -delete

	# remove compressed syslog files
	find /tmp -name *.log -type f ! -newer /tmp/comparefile -delete

	# remove date comparison file
	rm /tmp/comparefile

	# remove patch files
	for HOTFIX in `xe patch-list | grep "uuid ( RO)" | awk '{print $5}'`
	do
		xe patch-clean uuid="${HOTFIX}"
	done

	USAGE=`df -h | grep "/$" | head -n 1 | awk {' print $5 '} | sed -n -e "s/%//p"`
	echo "Disk usage after cleanup:  ${USAGE}%"
else
	echo "No need to cleanup"
fi