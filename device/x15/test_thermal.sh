#!/bin/bash -e

base="/sys/class/thermal"

echo -e "--------------------------------------------------------"
echo -e "|Thermal zone\t\t|temp\t\t|mode\t|"
echo -e "--------------------------------------------------------"
for i in `seq 0 5`
do
	type=$(cat ${base}/thermal_zone$i/type)
	temp=$(cat ${base}/thermal_zone$i/temp)
	mode=$(cat ${base}/thermal_zone$i/mode)

	echo -e "|${type}\t\t|${temp}\t\t|${mode}\t|"
done
echo -e "---------------------------------------------------------"
echo -e "|Cooling type\t\t|cur_state\t|max_state\t|"
echo -e "--------------------------------------------------------"
for i in `seq 0 2`
do
	type=$(cat ${base}/cooling_device$i/type)
	cur_state=$(cat ${base}/cooling_device$i/cur_state)
	max_state=$(cat ${base}/cooling_device$i/max_state)

	if [ "x${type}" = "xthermal-cpufreq-0" ] ; then
		echo -e "|${type}\t|${cur_state}\t\t|${max_state}\t\t|"
	else
		echo -e "|${type}\t\t|${cur_state}\t\t|${max_state}\t\t|"
	fi
done
echo -e "---------------------------------------------------------"

