#!/bin/bash

###################################################
# Do not change any contents of this script!
###################################################

# Some vars
myCONFIGFILE="/opt/moon/etc/moon.yml"
myCOMPOSEPATH="/opt/moon/etc/compose"
myRED="[0;31m"
myGREEN="[0;32m"
myWHITE="[0;0m"
myBLUE="[0;34m"

# Got root?
myWHOAMI=$(whoami)
if [ "$myWHOAMI" != "root" ]
  then
    echo "Need to run as root ..."
    sudo ./$0
    exit
fi

# Check for existing moon.yml
function fuCONFIGCHECK () {
  echo "### Checking for MoonStack configuration file ..."
  echo -n "###### $myBLUE$myCONFIGFILE$myWHITE "
  if ! [ -f $myCONFIGFILE ];
    then
      echo
      echo $myRED"Error - No MoonStack configuration file present."
      echo "Please copy one of the preconfigured configuration files from /opt/moon/etc/compose/*.yml to /opt/moon/etc/moon.yml."$myWHITE
      echo
      exit 1
    else
      echo $myGREEN"OK"$myWHITE
  fi
}

# Let's test the internet connection
function fuCHECKINET () {
mySITES=$1
  echo "### Now checking availability of ..."
  for i in $mySITES;
    do
      echo -n "###### $myBLUE$i$myWHITE "
      curl --connect-timeout 5 -IsS $i 2>&1>/dev/null
        if [ $? -ne 0 ];
          then
            echo
            echo $myRED"Error - Internet connection test failed. This might indicate some problems with your connection."
            echo "Exiting."$myWHITE
            echo
            exit 1
          else
            echo $myGREEN"OK"$myWHITE
        fi
  done;
}

function fuSELFUPDATE () {
  echo "### Now checking for newer files in repository ..."
  git fetch
  myREMOTESTAT=$(git status | grep -c "up-to-date")
  if [ "$myREMOTESTAT" != "0" ];
    then
      echo "###### $myBLUE"No updates found in repository."$myWHITE"
      return
  fi
  myRESULT=$(git diff --name-only origin/master | grep update.sh)
  myLOCALSTAT=$(git status -uno | grep -c update.sh)
  if [ "$myRESULT" == "update.sh" ];
    then
      if [ "$myLOCALSTAT" == "0" ];
        then
          echo "###### $myBLUE"Found newer version, will update myself and restart."$myWHITE"
          git pull --force
          exec "$1" "$2"
          exit 1
        else
          echo $myRED"Error - Update script was changed locally, cannot update."
          echo "Exiting."$myWHITE
          echo
          exit 1
      fi
    else
      echo "###### Update script is already up-to-date."
      git pull --force
  fi
}

# Only run with command switch
if [ "$1" != "-y" ]; then
  echo "This script will update / upgrade all MoonStack related scripts, tools and packages"
  echo "Some of your changes might be overwritten, so make sure to save your work"
  echo "This feature is still experimental, run with \"-y\" switch"
  echo
  exit
fi

echo "### Now running MoonStack update script."
echo

fuCHECKINET "https://gitee.com https://pypi.python.org https://mirrors.aliyun.com/ubuntu https://get.daocloud.io"
echo

fuSELFUPDATE "$0" "$@"
echo

fuCONFIGCHECK
echo

echo "### Now stopping MoonStack"
systemctl stop moon

# Better safe than sorry
echo "###### Creating backup and storing it in /home/msec"
tar cvfz /root/moon_backup.tgz /opt/moon

echo "###### Getting the current install flavor"
myFLAVOR=$(head $myCONFIGFILE -n 1 | awk '{ print $3 }' | tr -d :'()':)

echo "###### Updating compose file"
case $myFLAVOR in
  HP)
    echo "###### Restoring HONEYPOT flavor installation."
    cp $myCOMPOSEPATH/hp.yml $myCONFIGFILE
  ;;
  Industrial)
    echo "###### Restoring INDUSTRIAL flavor installation."
    cp $myCOMPOSEPATH/industrial.yml $myCONFIGFILE
  ;;
  Standard)
    echo "###### Restoring moon flavor installation."
    cp $myCOMPOSEPATH/moon.yml $myCONFIGFILE
  ;;
  Everything)
    echo "###### Restoring EVERYTHING flavor installation."
    cp $myCOMPOSEPATH/all.yml $myCONFIGFILE
  ;;
esac

echo
echo "### Now upgrading packages"
cp /opt/moon/iso/install/sources.list /etc/apt/sources.list
apt-get autoclean -y
apt-get autoremove -y
apt-get update
apt-get dist-upgrade -y
pip install --upgrade pip
pip install docker-compose==1.16.1
pip install elasticsearch-curator==5.2.0
ln -s /usr/bin/nodejs /usr/bin/node 2>&1
npm install https://gitee.com/stackw0rm/wetty.git -g
npm install https://gitee.com/stackw0rm/elasticsearch-dump.git -g
wget hhttp://www.moonstack.org/down/ctop-0.6.1-linux-amd64 -O /usr/bin/ctop && chmod +x /usr/bin/ctop
/opt/moon/iso/installer/set_mirror.sh http://f1361db2.m.daocloud.io
systemctl stop docker
systemctl start docker


echo
echo "### Now replacing MoonStack related config files on host"
cp    host/etc/systemd/* /etc/systemd/system/
cp    host/etc/issue /etc/
cp -R host/etc/nginx/ssl /etc/nginx/
cp    host/etc/nginx/moonweb.conf /etc/nginx/sites-available/
cp    host/etc/nginx/nginx.conf /etc/nginx/nginx.conf
cp    host/usr/share/nginx/html/* /usr/share/nginx/html/

echo
echo "### Now reloading systemd, nginx"
systemctl daemon-reload
nginx -s reload

echo
echo "### Now restarting wetty, nginx, docker"
systemctl restart wetty.service
systemctl restart nginx.service
systemctl restart docker.service

echo
echo "### Now pulling latest docker images"
docker-compose -f /opt/moon/etc/moon.yml pull

echo
echo "### Now starting MoonStack service"
systemctl start moon

echo
echo "### If you made changes to moon.yml please ensure to add them again."
echo "### We stored the previous version as backup in /home/msec."
echo "### Done."
