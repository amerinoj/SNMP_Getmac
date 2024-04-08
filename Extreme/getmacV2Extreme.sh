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

				Vlan_Id_Table=$(snmpwalk -v2c  -c $COMMUNITY $DEVICE 1.3.6.1.4.1.1916.1.2.1.2.1.10 2>/dev/null | awk -F '[.: ]' '{print $11","$15}'| sort -k 1b,1)
				Vlan_Name_Table=$(snmpwalk -v2c  -c $COMMUNITY $DEVICE  1.3.6.1.4.1.1916.1.2.1.2.1.2 2>/dev/null |awk -F '[.: ]' '{print $11","$15}'|sort -k 1b,1)
						
				Main_Table=$(join -t',' -a1 <(echo "$Vlan_Name_Table") <(echo "$Vlan_Id_Table"))
             
				Mac_Index_Table=$(snmpwalk -v2c  -c $COMMUNITY $DEVICE  1.3.6.1.4.1.1916.1.16.4.1.1 2>/dev/null | awk -F '[.: ]' '{print tolower($16","$20":"$21":"$22":"$23":"$24":"$25)}'| sort -u -k1)
			
				
				for i in $Mac_Index_Table ; do 
					IFS=',' read -r -a Mac_Array <<< "$i" 
					Id="${Mac_Array[0]}"
					Mac_number="${Mac_Array[1]}"
					for Vlan_info in $Main_Table; do
						IFS=',' read -r -a Info_Array <<< "$Vlan_info" 
						if [ "${Info_Array[0]}" -eq "$Id" ]; then
							Vlan_Name="${Info_Array[1]}"
							Vlan_id="${Info_Array[2]}"

							echo -e "$DEVICE,$HOST,$Vlan_Name,$Vlan_id,$Mac_number"  >> $REPORT.tmp

							
						fi
						
					done
					
				done
           




         fi
         }
 done

#End snmp pull
echo -e "nSNMP Queries Completed"
sort -t"," -b -k4,5 -u  $REPORT.tmp > $REPORT.mac
rm $REPORT.tmp
# Count mac per vlan
echo "[*]Count mac per vlan...."
awk -F, 'NR>1{arr[$3","$4]++}END{for (a in arr) print  a","arr[a]}' $REPORT.mac  >> $REPORT.csv


echo -e "Count Completed"



