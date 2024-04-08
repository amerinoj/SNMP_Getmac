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
 D_TYPE=0

#Location MIB
 BRIDGE_MIB="$SCRIPTPATH/BRIDGE-MIB.mib"
 VTP_MIB="$SCRIPTPATH/CISCO-VTP-MIB.mib"
 ENTITY_MIB="$SCRIPTPATH/ENTITY-MIB.txt"



#Create CSV file and set header
 echo -e "Vlan_name,Vlan_id,Number_of_mac" > $REPORT.csv

#Loop through devices in list
 for DEVICE in $LIST ; do {
		#Reset Device type
		D_TYPE=0
		
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

				########## GET VLAN TABLE SECCTION #######################
				#Alcatel/Enterasys/Extreme  
				Vlan_Id_Table=$(snmpwalk -v2c  -c $COMMUNITY $DEVICE \
					1.3.6.1.2.1.17.7.1.4.3.1.1 2>/dev/null | awk -F '[.: ]' '{if ($0 ~ /No Such Object/) {print ""} else{ print $11","$15$16$17}}')
					
				if [[ -z $Vlan_Id_Table ]]; then #SI Vlan_Id_Table es igual a null
					#Cisco
					D_TYPE=1
					Vlan_Id_Table=$(snmpwalk -v2c  -c $COMMUNITY $DEVICE \
						1.3.6.1.4.1.9.9.46.1.3.1.1.4 2>/dev/null | awk -F '[.: ]' '{if ($0 ~ /No Such Object/) {print ""} else{ print $13","$17$18$19}}')

				fi
				
				#echo "VLAN table of $DEVICE,$HOST"
				#echo "$Vlan_Id_Table"
				################################################################
				########## GET MAC TABLE SECCTION #######################
				
   				if [[ -n $Vlan_Id_Table ]]; then #SI Vlan_Id_Table no  es null
				    #Alcatel/HP/Enterasys/Cisco
					Mac_Index_Table=$(snmpwalk -v2c  -c $COMMUNITY $DEVICE  \
						1.3.6.1.2.1.17.7.1.2.2.1.2 | awk -F '[.: ]' '{if ($0 ~ /No Such Object/) {print ""} else{printf("%d,%.2x:%.2x:%.2x:%.2x:%.2x:%.2x\n",  $11,$12,$13,$14,$15,$16,$17)}}')
					if [[ -z $Mac_Index_Table ]]; then #SI Mac_Index_Table es igual a null
					#Extreme
						D_TYPE=2
						Index_Id_Table=$(snmpwalk -v2c  -c $COMMUNITY $DEVICE \
							1.3.6.1.4.1.1916.1.2.1.2.1.10 2>/dev/null | awk -F '[.: ]' '{if ($0 ~ /No Such Object/) {print ""} else{print $11","$15}}'| sort -k 1b,1)
						if [[ -n $Index_Id_Table ]]; then #SI Index_Id_Table no es null
							Mac_Exteme=$(snmpwalk -v2c  -c $COMMUNITY $DEVICE \
							1.3.6.1.4.1.1916.1.16.4.1.1 2>/dev/null | awk -F '[.: ]' '{if ($0 ~ /No Such Object/) {print ""} else {print tolower($16","$20":"$21":"$22":"$23":"$24":"$25)}}'| sort -u -k1)
							
							if [[ -n $Mac_Exteme ]]; then #SI Mac_Exteme no es null
								Mac_Index_Table=$(join -t',' -a1 <(echo "$Mac_Exteme") <(echo "$Index_Id_Table") | cut -d"," -f2,3 | \
									sort -t"," -k1 | awk -F '[,]' '{if ($0 ~ /No Such Object/) {print ""} else{print $2","$1}}'| sort -k 1b,1)
							else
								echo -e "[*]MAC OID Extreme No Compatible... $DEVICE,$HOST"
								echo -e "$DEVICE,$HOST,MAC OID Extreme No Compatible" >> $REPORT.csv
								echo >> $REPORT.csv
							fi
						else
							echo -e "[*]MAC OID No Compatible... $DEVICE,$HOST"
							echo -e "$DEVICE,$HOST,MAC OID No Compatible" >> $REPORT.csv
							echo >> $REPORT.csv
						fi
						
					fi
					
					#Print device type
					case $D_TYPE in
					  0)
						echo -e "		--> Generic device detected $HOST"
						;;

					  1)
						echo -e "		--> CISCO device detected $HOST"
						;;

					  2)
						echo -e "		--> EXTREME device detected $HOST"
						;;

					  *)
						echo -e "		--> Generic device detected $HOST"
						;;
					esac
										
					#echo "mac table of $DEVICE,$HOST"
					#echo "$Mac_Index_Table"
				################################################################
				########## JOIN MAC TABLE AND VLAN TABLE #######################
					for i in $Mac_Index_Table ; do 
						IFS=',' read -r -a Mac_Array <<< "$i" 
						Id="${Mac_Array[0]}"
						Mac_number="${Mac_Array[1]}"
						for Vlan_info in $Vlan_Id_Table; do
							IFS=',' read -r -a Info_Array <<< "$Vlan_info" 
							Vlan_id="${Info_Array[0]}"
							if [ "$Vlan_id" -eq "$Id" ]; then
								Vlan_Name="${Info_Array[1]}"		
															
								echo -e "$DEVICE,$HOST,$Vlan_Name,$Vlan_id,$Mac_number"  >> $REPORT.mac

								
							fi
							
						done
						
					done
					
					################################################################
					##################### DROP DUPLICATES ##########################					
					sort -t ',' -b -k4,5 -u $REPORT.mac  > $REPORT.mac.tmp 
					mv $REPORT.mac.tmp $REPORT.mac
					
				else
					    echo -e "[*]Vlan OID No Compatible... $DEVICE,$HOST"
                        echo -e "$DEVICE,$HOST,Vlan OID No Compatible" >> $REPORT.csv
                        echo >> $REPORT.csv
				fi




         fi
         }
 done
 

#End snmp pull
echo -e "nSNMP Queries Completed"
# Count mac per vlan
echo "[*]Count mac per vlan...."
awk -F, 'NR>1{arr[$3","$4]++}END{for (a in arr) print  a","arr[a]}' $REPORT.mac  >> $REPORT.csv


echo -e "Count Completed"
