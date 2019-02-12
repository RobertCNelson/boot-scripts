#!/bin/bash -e

base="/sys/class/thermal"

echo -e "------------------------------------------------------------------------------------------------"
echo -e "|Thermal zone\t\t|temp\t|mode\t\t|cdev0_type\t|cdev1_type"
echo -e "------------------------------------------------------------------------------------------------"
for i in `seq 0 5`
do
	if [ -d ${base}/thermal_zone$i/ ] ; then
		type=$(cat ${base}/thermal_zone$i/type)
		temp=$(cat ${base}/thermal_zone$i/temp)
		mode=$(cat ${base}/thermal_zone$i/mode)

		if [ -d ${base}/thermal_zone$i/cdev0 ] ; then
			cdev0_type=$(cat ${base}/thermal_zone$i/cdev0/type)
		else
			cdev0_type="\t"
		fi

		if [ -d ${base}/thermal_zone$i/cdev1 ] ; then
			cdev1_type=$(cat ${base}/thermal_zone$i/cdev1/type)
		else
			cdev1_type="\t"
		fi

		if [ -f ${base}/thermal_zone$i/trip_point_0_temp ] ; then
			trip_point_0_temp=$(cat ${base}/thermal_zone$i/trip_point_0_temp)
			trip_point_0_type=$(cat ${base}/thermal_zone$i/trip_point_0_type)
			trip_point_0="${trip_point_0_type}:${trip_point_0_temp}|"
		else
			trip_point_0=""
		fi

		if [ -f ${base}/thermal_zone$i/trip_point_1_temp ] ; then
			trip_point_1_temp=$(cat ${base}/thermal_zone$i/trip_point_1_temp)
			trip_point_1_type=$(cat ${base}/thermal_zone$i/trip_point_1_type)
			trip_point_1="${trip_point_1_type}:${trip_point_1_temp}|"
		else
			trip_point_0=""
		fi

		if [ -f ${base}/thermal_zone$i/trip_point_2_temp ] ; then
			trip_point_2_temp=$(cat ${base}/thermal_zone$i/trip_point_2_temp)
			trip_point_2_type=$(cat ${base}/thermal_zone$i/trip_point_2_type)
			trip_point_2="${trip_point_2_type}:${trip_point_2_temp}|"
		else
			trip_point_2=""
		fi

		if [ "x${cdev1_type}" = "xthermal-cpufreq-0" ] ; then
			echo -e "|${type}\t\t|${temp}\t|${mode}\t|${cdev0_type}\t|${cdev1_type}\t|${trip_point_0}${trip_point_1}${trip_point_2}"
		else
			echo -e "|${type}\t\t|${temp}\t|${mode}\t|${cdev0_type}\t|${cdev1_type}\t\t|${trip_point_0}${trip_point_1}${trip_point_2}"
		fi
	fi
done
echo -e "------------------------------------------------------------------------------------------------"
echo -e "|Cooling type\t\t|state\t|max_state\t|"
echo -e "------------------------------------------------------------------------------------------------"
for i in `seq 0 2`
do
	if [ -d ${base}/cooling_device$i/ ] ; then
		type=$(cat ${base}/cooling_device$i/type)
		cur_state=$(cat ${base}/cooling_device$i/cur_state)
		max_state=$(cat ${base}/cooling_device$i/max_state)

		if [ "x${type}" = "xthermal-cpufreq-0" ] ; then
			echo -e "|${type}\t|${cur_state}\t|${max_state}\t\t|"
		else
			echo -e "|${type}\t\t|${cur_state}\t|${max_state}\t\t|"
		fi
	fi
done
echo -e "------------------------------------------------------------------------------------------------"

