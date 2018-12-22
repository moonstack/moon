#!/bin/bash

# set backtitle, get filename
myBACKTITLE="MoonStack Edition Selection Tool"
myYMLS=$(cd /opt/moon/etc/compose/ && ls -1 *.yml)
myLINK="/opt/Moon/etc/moon.yml"

# Let's load docker images in parallel
function fuPULLIMAGES {
local myMOONCOMPOSE="/opt/moon/etc/moon.yml"
for name in $(cat $myMOONCOMPOSE | grep -v '#' | grep image | cut -d'"' -f2 | uniq)
  do
    docker pull $name &
  done
wait
echo
}

# setup menu
for i in $myYMLS;
  do
    myITEMS+="$i $(echo $i | cut -d "." -f1 | tr [:lower:] [:upper:]) "
done
myEDITION=$(dialog --backtitle "$myBACKTITLE" --menu "Select Moonstack Edition" 13 50 6 $myITEMS 3>&1 1>&2 2>&3 3>&-)
if [ "$myEDITION" == "" ];
  then
    echo "Have a nice day!"
    exit
fi
dialog --backtitle "$myBACKTITLE" --title "[ Activate now? ]" --yesno "\n$myEDITION" 7 50
myOK=$?
if [ "$myOK" == "0" ];
  then
    echo "OK - Activating and downloading latest images."
    systemctl stop moon
    if [ "$(docker ps -aq)" != "" ];
      then
        docker stop $(docker ps -aq)
        docker rm $(docker ps -aq)
    fi
    rm -f $myLINK
    ln -s /opt/moon/etc/compose/$myEDITION $myLINK
    fuPULLIMAGES
    systemctl start moon
    echo "Done. Use \"dps.sh\" for monitoring"
  else
    echo "Have a nice day!"
fi
