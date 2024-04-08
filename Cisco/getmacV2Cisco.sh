#!/bin/bash 
#set -e
# Help prompt
 if [ $# -eq 0 ] || [ $1 == "-help" ]; then
  echo  "########### Command usage:###########"
  echo  "./getmacV2.sh [community] [list] [report_file]";
  echo  "###########PARAMETERS###########
  [community]=community name snmpv2
  [Host_list]=host list ip
  [report_file.csv]=csv report file name"  
  
  echo  "Example:
  sh getmacV2.sh comm123  ListadoEquipos.txt reporte"
  exit 1
 fi

# Set VARs
 COMMUNITY="$1"
 LIST=$(cat $2)
 REPORT="$3"
 SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"


#Location MIB
 BRIDGE_MIB="$SCRIPTPATH/BRIDGE-MIB.mib"
 VTP_MIB="$SCRIPTPATH/CISCO-VTP-MIB.mib"
 ENTITY_MIB="$SCRIPTPATH/ENTITY-MIB.txt"



#Create CSV file and set header
 echo -e "Vlan_name,Vlan_id,Number_of_mac" > $REPORT.csv

#Loop through devices in list
 for DEVICE in $LIST ; do {

	#Get hostname from device
	 HOST=$(snmpget -v2c -c $COMMUNITY -Oqv $DEVICE SNMPv2-MIB::sysName.0)

	
	#Check the host response
	 if [[ $HOST == "" ]]; then
			echo -e "[*]No Response... $DEVICE"
			echo -e "$DEVICE,No Response" >> $REPORT.csv
			echo >> $REPORT.csv
	 else
		#Working
		echo "Working.... $DEVICE,$HOST" 
		
		#Vlan list
		 Vlan_List=$(snmpwalk -v2c  -c $COMMUNITY $DEVICE 1.3.6.1.4.1.9.9.46.1.3.1.1.4 2>/dev/null | cut -d . -f11 | awk -F " " '{print $1,$4}' )
		 while IFS=$'\n' read -r vlan; do
			array_vlan=($vlan);
			Vlan_id=${array_vlan[0]};
			Vlan_name=${array_vlan[1]^^};
			#echo $Vlan_id  $Vlan_name
			
			#Mac list
			Mac_List=($(snmpwalk -v2c -m+$BRIDGE_MIB -c $COMMUNITY'@'$Vlan_id $DEVICE dot1dTpFdbAddress 2>/dev/null | awk -F ": " '{print $2}'))	
			#echo "${Mac_List[@]}"
			
			for i in "${!Mac_List[@]}"; do
				echo -e "$DEVICE,$HOST,$Vlan_name,$Vlan_id,${Mac_List[$i]}"  >> $REPORT.mac
				sort -t ',' -b -k4,5 -u $REPORT.mac  > $REPORT.mac.tmp 
				mv $REPORT.mac.tmp $REPORT.mac
			
			done

		done <<< "$Vlan_List"


		
	
	 fi
	 }
 done
 
#End snmp pull
echo -e "nSNMP Queries Completed" 

# Count mac per vlan
echo "[*]Count mac per vlan...." 
awk -F, 'NR>1{arr[$3","$4]++}END{for (a in arr) print  a","arr[a]}' $REPORT.mac  >> $REPORT.csv


echo -e "Count Completed"

