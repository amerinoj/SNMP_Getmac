#!/bin/bash
#set -e
# Help prompt
 if [ $# -eq 0 ] || [ $1 == "-help" ]; then
  echo  "########### Command usage:###########"
  echo  "./JoinFiles.sh FileName1 FileName2 FileNameOutput";
  echo  "###########PARAMETERS###########
  [FileName1]=First File name .mac
  [FileName2]=Second File name .mac
  [FileNameOutput.csv]=csv joined file name"

  echo  "Example:
  sh JoinFiles.sh Listado1.mac  Listado2.mac ListadoUnido.csv"
  exit 1
 fi

# Set VARs
 FileName1="$1"
 FileName2="$2"
 REPORT="$3"
 SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"


# Count mac per vlan
echo "[*]Count mac per vlan...."


cat $FileName1 $FileName2  > $REPORT.mac.tmp
cat  $REPORT.mac.tmp | sort | uniq > $REPORT.mac
rm	$REPORT.mac.tmp

echo -e "Vlan_name,Vlan_id,Number_of_mac" > $REPORT.csv
awk -F, 'NR>1{arr[$3","$4]++}END{for (a in arr) print  a","arr[a]}' $REPORT.mac  >> $REPORT.csv

echo -e "Count Completed"
