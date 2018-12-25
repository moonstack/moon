#!/bin/bash
# Backup all ES relevant folders
# Make sure ES is available
myES="http://127.0.0.1:64298/"
myESSTATUS=$(curl -s -XGET ''$myES'_cluster/health' | jq '.' | grep -c green)
if ! [ "$myESSTATUS" = "1" ]
  then
<<<<<<< HEAD
    echo "### Elasticsearch is not available, try starting via 'systemctl start moon'."
=======
    echo "### Elasticsearch is not available, try starting via 'systemctl start MoonStack'."
>>>>>>> origin/master
    exit
  else
    echo "### Elasticsearch is available, now continuing."
    echo
fi

# Set vars
myCOUNT=1
myDATE=$(date +%Y%m%d%H%M)
myELKPATH="/data/elk/data"
myKIBANAINDEXNAME=$(curl -s -XGET ''$myES'_cat/indices/' | grep -w ".kibana_1" | awk '{ print $4 }')
myKIBANAINDEXPATH=$myELKPATH/nodes/0/indices/$myKIBANAINDEXNAME

# Let's ensure normal operation on exit or if interrupted ...
function fuCLEANUP {
  ### Start ELK
  systemctl start moon
  echo "### Now starting MoonStack ..."
}
trap fuCLEANUP EXIT

# Stop MoonStack to lift db lock
echo "### Now stopping MoonStack"
systemctl stop moon
sleep 2

# Backup DB in 2 flavors
echo "### Now backing up Elasticsearch folders ..."
tar cvfz "elkall_"$myDATE".tgz" $myELKPATH
tar cvfz "elkbase_"$myDATE".tgz" $myKIBANAINDEXPATH
