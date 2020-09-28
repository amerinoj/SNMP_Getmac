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
 BRIDGE_MIB="$SCRIPTPATH/BRIDGE-MIB.mib"
 VTP_MIB="$SCRIPTPATH/CISCO-VTP-MIB.mib"
 ENTITY_MIB="$SCRIPTPATH/ENTITY-MIB.txt"



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
		 Vlan_List=$(snmpwalk -v3  -u $USER -a $AUTHP -A $PASSWORD -x $PRIVP -X $PASSWORD -l authPriv $DEVICE  1.3.6.1.4.1.9.9.46.1.3.1.1.4 2>/dev/null | cut -d . -f11 | awk -F " " '{print $1,$4}' )
		 while IFS=$'\n' read -r vlan; do
			array_vlan=($vlan);
			Vlan_id=${array_vlan[0]};
			Vlan_name=${array_vlan[1]^^};
			#echo $Vlan_id  $Vlan_name
			
			#Mac list
			Mac_List=($(snmpwalk -v3 -m+$BRIDGE_MIB -u $USER -a $AUTHP -A $PASSWORD -x $PRIVP -X $PASSWORD -l authPriv -n vlan-$Vlan_id $DEVICE  dot1dTpFdbAddress 2>/dev/null | awk -F ": " '{print $2}')) 	
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

