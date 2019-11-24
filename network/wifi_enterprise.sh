#!/bin/bash

reset

#Promt for root password
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

wifi=()

until ((${#wifi[@]} > 0)); do

    printf " Scanning Wifi...\n"

    connmanctl enable wifi > /dev/null 2>&1
    connmanctl scan wifi > /dev/null 2>&1
    connmanctl anget on  > /dev/null 2>&1
    wifi=$(connmanctl services)

    wifi=(${wifi// / })

    if [ ${wifi[0]} = "*AR" ]||[ ${wifi[0]} = "*AO" ]; then
        wifi=("${wifi[@]:1}") #removed the 1st parameter
    fi


done

for i in "${!wifi[@]}"; do
    if (( $(($i % 2 )) == 0 )); then
        # i="$(($i-1))"
        ssids+=(${wifi[i]})
    fi
done

printf "\n\tFound SSIDS:\n\n"
for i in "${!ssids[@]}"
do
    printf "    [$i] - ${ssids[i]}\n"
done

ssid=-1

until (($ssid >= 0)) && (($ssid <= $((${#ssids[@]})))); do
    printf "\n Enter SSID #, [0-$((${#ssids[@]}-1))]: "
    read ssid

    ssid=${ssids[$ssid]}
    valid="N"
    printf " You selected $ssid, is that correct? [y/N]:"
    read valid

    if [ "$valid" = "Y" ]||[ "$valid" = "y" ]; then
        :
    else
        ssid=-1
    fi

done

printf "\n Username: "
read username
printf " Password: "
read -s password

for (( i=0;i<=${#wifi[*]};i++ ))
do

    if [ "${wifi[$i]}" == "$ssid" ];then
            ssid=${wifi[$i+1]}

            printf "[service_$ssid]\n" > /var/lib/connman/$ssid.config
            printf "Type = wifi\n" >> /var/lib/connman/$ssid.config

            ssid_name=(${ssid//_/ })

            printf "SSID = ${ssid_name[2]}\n" >> /var/lib/connman/$ssid.config
            printf "EAP = peap\n" >> /var/lib/connman/$ssid.config
            printf "Phase2 = MSCHAPV2\n" >> /var/lib/connman/$ssid.config
            printf "Identity= $username\n" >> /var/lib/connman/$ssid.config
            printf "Passphrase= $password\n" >> /var/lib/connman/$ssid.config

            printf "\nWrote config to: /var/lib/connman/$ssid.config\n"

            service connman restart

            break
    fi

done










# file.write("[service_"+ ssid[1] + "]\n")		# Use tamulink detailed ssid for file title
# file.write("Type = wifi\n")				# this is a WiFi file
# file.write("SSID = " + connmanctl_ssid[2] + "\n")	# Set SSID to detailed SSID
# file.write("EAP = peap\n")				# Set type of encapsulation
# file.write("Phase2 = MSCHAPV2\n")			# Set type of authentication for network
# file.write("Identity= " + username + "\n")		# Set network username
# file.write("Passphrase= " + password + "\n")		# Set network password

# [service_wifi_38d269e00e73_74616d756c696e6b2d777061_managed_ieee8021x]
# [service_wifi_38d269e00e73_74616d756c696e6b2d777061_managed_ieee8021x]

# Type = wifi
# SSID = 74616d756c696e6b2d777061
# EAP = peap
# Phase2 = MSCHAPV2
# Identity= ansarid
# Passphrase= DaniTAMU083098
