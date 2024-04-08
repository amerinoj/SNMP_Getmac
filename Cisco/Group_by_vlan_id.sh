#!/bin/bash 
#set -e
# Help prompt
 if [ $# -eq 0 ] || [ $1 == "-help" ]; then
  echo  "########### Command usage:###########"
  echo  "./Group_by_vlan_id.sh report_name.mac";
  echo  "###########PARAMETERS###########
  [report_file.csv]=report file name" 
  echo  "Example:
  sh Group_by_vlan_id.sh report"
  exit 1
 fi
 

REPORT="$1"

#Create CSV file and set header
 echo -e "Vlan_name,Vlan_id,Number_of_mac" > $REPORT.grp.csv
			
Vlans=$(sort -t,  -k4,1 -n -u -b $REPORT  | cut -d ','  -f 3,4 --output-delimiter=' '  |  sort   -k2 -n -u -b)
Vlan_count=$(awk -F, '{arr[$4]++;next } END{for (a in arr)   print a,arr[a] }' $REPORT ) 
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
			echo -e "$Vlan_Name,$Id,$Count"  >> $REPORT.grp.csv
done <<< "$Vlan_count"

echo -e "Group Completed"
