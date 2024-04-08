#!/bin/bash 
#set -e
# Help prompt
 if [ $# -eq 0 ] || [ $1 == "-help" ]; then
  echo  "########### Command usage:###########"
  echo  "./getmacV3.sh [user] [password] [auth_proto] [privacy_proto] [Host_list] [report_file]";
  echo  "###########PARAMETERS###########
  [user]=username snmpv3
  [password]=password
  [auth_proto]=authentication protocol ej:SHA
  [privacy_proto]=privacy protocol ej:DES
  [Host_list]=host list ip
  [report_file.csv]=csv report file name" 
  
  echo  "Example:
  sh getmacV3.sh user1 12345  MD5 AES ListadoEquipos.txt reporte"
  exit 1
 fi

# Set VARs
 USER="$1"
 PASSWORD="$2"
 AUTHP="$3"
 PRIVP="$4"
 LIST=$(cat $5)
 REPORT="$6"
 SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"


#Location MIB
 ALC_IND_MIB="$SCRIPTPATH/ALCATEL-IND1-VLAN-MGR-MIB.mib"



#Create CSV file and set header
 echo -e "Vlan_name,Vlan_id,Number_of_mac" > $REPORT.csv

#Loop through devices in list
 for DEVICE in $LIST ; do {

	#Get hostname from device
	 HOST=$(snmpget -v3  -u $USER -a $AUTHP -A $PASSWORD -x $PRIVP -X $PASSWORD -l authPriv $DEVICE sysName.0 | awk 'BEGIN {FS=": "} {print $2}')

	
	#Check the host response
	 if [[ $HOST == "" ]]; then
			echo -e "[*]No Response... $DEVICE"
			echo -e "$DEVICE,No Response" >> $REPORT.csv
			echo >> $REPORT.csv
	 else
		#Working
		echo "Working.... $DEVICE,$HOST" 
		
		#Vlan list
		 Vlan_List=$(snmpwalk -v3  -u $USER -a $AUTHP -A $PASSWORD -x $PRIVP -X $PASSWORD -l authPriv $DEVICE  1.3.6.1.4.1.6486.800.1.2.1.3.1.1.1.1.1.2 2>/dev/null | cut -d . -f14 | awk -F " " '{print $1,$4}' | sort  -k1n    )
		 
		#Mac list
		Mac_List=$(snmpwalk -v3  -u $USER -a $AUTHP -A $PASSWORD -x $PRIVP -X $PASSWORD -l authPriv $DEVICE  1.3.6.1.4.1.6486.800.1.2.1.8.1.1.1.1.1 2>/dev/null |  awk -F "." '{print $14,$20}' | awk -F " " '{print $1,$5":"$6":"$7":"$8":"$9":"$10}' | sort  -k1n   ) 
			
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
			#echo "Found:" $Vlanid  $Vlan_Name
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



echo -e "Count Completed"
