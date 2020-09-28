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
 ALC_IND_MIB="$SCRIPTPATH/ALCATEL-IND1-VLAN-MGR-MIB.mib"



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
		 Vlan_List=$(snmpwalk -v2c  -c $COMMUNITY $DEVICE  1.3.6.1.4.1.6486.800.1.2.1.3.1.1.1.1.1.2 2>/dev/null | cut -d . -f14 | awk -F " " '{print $1,$4}' | sort  -k1n    )
		 
		#Mac list
		Mac_List=$(snmpwalk -v2c  -c $COMMUNITY $DEVICE  1.3.6.1.4.1.6486.800.1.2.1.8.1.1.1.1.1 2>/dev/null |  awk -F "." '{print $14,$20}' | awk -F " " '{print $1,$5":"$6":"$7":"$8":"$9":"$10}' | sort  -k1n   ) 
			
		 while IFS=$'\n' read -r Mac; do
			array_Mac=($Mac);
			Vlan_id=${array_Mac[0]};
			Mac_number=${array_Mac[1]^^};
			Vlan_Name='';
			while IFS=$'\n' read -r Vlan; do
				array_Vlan=($Vlan);
				Vlanid=${array_Vlan[0]};
				Vlan_Name=${array_Vlan[1]^^};
				
					if [[ "$Vlanid" == "$Vlan_id" ]] ; then
						break 1
					fi
				
			done <<< "$Vlan_List"
			echo "Found:" $Vlanid  $Vlan_Name
			echo -e "$DEVICE,$HOST,$Vlan_Name,$Vlan_id,$Mac_number"  >> $REPORT.mac

		done <<< "$Mac_List"

		sort -t ',' -b -k4,5 -u $REPORT.mac  > $REPORT.mac.tmp 
		mv $REPORT.mac.tmp $REPORT.mac
		

		
	
	 fi
	 }
 done
 
#End snmp pull
echo -e "nSNMP Queries Completed" 

# Count mac per vlan
echo "[*]Count mac per vlan...." 
awk -F, 'NR>1{arr[$3","$4]++}END{for (a in arr) print  a","arr[a]}' $REPORT.mac  >> $REPORT.csv

/*
Vlans=$(sort -t,  -k4,1 -n -u -b $REPORT.mac  | cut -d ","  -f 3,4 --output-delimiter=" "  |  sort   -k2 -n -u -b)
Vlan_count=$(awk -F, '{arr[$4]++;next } END{for (a in arr)   print a,arr[a] }' $REPORT.mac ) 

while IFS=$'\n' read -r Line; do
			array_Vlan_id=($Line);
			Id=${array_Vlan_id[0]};
			Count=${array_Vlan_id[1]};
			
			while IFS=$'\n' read -r Vlan; do
				array_Vlan=($Vlan);
				Vlan_Name=${array_Vlan[0]};
				Vlanid=${array_Vlan[1]};
				
					if [[ "$Vlanid" == "$Id" ]] ; then
						break 1
					fi
				
			done <<< "$Vlans"
			echo -e "$Vlan_Name,$Id,$Count"  >> $REPORT.csv
done <<< "$Vlan_count"
*/

echo -e "Count Completed"