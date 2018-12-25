#!/bin/bash

# 一些全局变量
myCONFIGFILE="/opt/moon/etc/moon.yml"
myCOMPOSEPATH="/opt/moon/etc/compose"
myRED="[0;31m"
myGREEN="[0;32m"
myWHITE="[0;0m"
myBLUE="[0;34m"


# 检查现有的moon.yml
function fuCONFIGCHECK () {
  echo "### 检查MoonStack配置文件 ..."
  echo -n "###### $myBLUE$myCONFIGFILE$myWHITE "
  if ! [ -f $myCONFIGFILE ];
    then
      echo
      echo "[ $myRED""错误""$myWHITE ] - 没有找到MoonStack配置文件."
      echo "请创建所需要的配置文件链接 例如. 'ln -s /opt/moon/etc/compose/standard.yml /opt/moon/etc/moon.yml'."
      echo
      exit 1
    else
      echo "[ $myGREEN""成功""$myWHITE ]"
  fi
echo
}

# 测试公网连接
function fuCHECKINET () {
mySITES=$1
  echo "### 现在检查 ..."
  for i in $mySITES;
    do
      echo -n "###### $myBLUE$i$myWHITE "
      curl --connect-timeout 5 -IsS $i 2>&1>/dev/null
        if [ $? -ne 0 ];
          then
	    echo
            echo "###### $myBLUE""错误 - 互联网连接测试失败.""$myWHITE"" [ $myRED""错误""$myWHITE ]"
            echo "退出.""$myWHITE"
            echo
            exit 1
          else
            echo "[ $myGREEN"OK"$myWHITE ]"
        fi
  done;
echo
}

# 升级
function fuSELFUPDATE () {
  echo "### 检查新版本 ..."
  git fetch --all
  myREMOTESTAT=$(git status | grep -c "up-to-date")
  if [ "$myREMOTESTAT" != "0" ];
    then
      echo "###### $myBLUE""您使用的是最新版本.""$myWHITE"
      return
  fi
  myRESULT=$(git diff --name-only origin/master | grep update.sh)
  if [ "$myRESULT" == "update.sh" ];
    then
      echo "###### $myBLUE""找到新版本, 将获取更新并重启MoonStack.""$myWHITE"
      git reset --hard
      git pull --force
      exec "$1" "$2"
      exit 1
    else
      echo "###### $myBLUE""获取最新更新""$myWHITE"
      git reset --hard
      git pull --force
  fi
echo
}

# 检查版本
function fuCHECK_VERSION () {
local myMINVERSION="v1.1"
local myMASTERVERSION="v1.2"
echo
echo "### 检查版本号 ..."
if [ -f "版本号" ];
  then
    myVERSION=$(cat version)
    if [[ "$myVERSION" > "$myMINVERSION" || "$myVERSION" == "$myMINVERSION" ]] && [[ "$myVERSION" < "$myMASTERVERSION" || "$myVERSION" == "$myMASTERVERSION" ]]
      then
        echo "###### $myBLUE$myVERSION 符合更新条件.$myWHITE"" [ $myGREEN""完成""$myWHITE ]"
      else
        echo "###### $myBLUE $myVERSION 无法完成自动更新,请重新安装.$myWHITE"" [ $myRED""错误""$myWHITE ]"
	exit
    fi
  else
    echo "###### $myBLUE""无法确定版本. 请从 '/opt/moon' 运行 'update.sh'.""$myWHITE"" [ $myRED""错误""$myWHITE ]"
    exit
  fi
echo
}


# 停止Moonstack,避免和当前正在运行的MoonStack发生冲突
function fuSTOP_MOON () {
echo "### 需要停止当前运行的 MoonStack ..."
echo -n "###### $myBLUE 正在停止当前运行的 MoonStack.$myWHITE "
systemctl stop moon
if [ $? -ne 0 ];
  then
    echo " [ $myRED""错误""$myWHITE ]"
    echo "###### $myBLUE""无法停止当前运行的MoonStack.""$myWHITE"" [ $myRED""错误""$myWHITE ]"
    echo "退出.""$myWHITE"
    echo
    exit 1
  else
    echo "[ $myGREEN"成功"$myWHITE ]"
    echo "###### $myBLUE 正在清理容器.$myWHITE "
    if [ "$(docker ps -aq)" != "" ];
      then
        docker stop $(docker ps -aq)
        docker rm $(docker ps -aq)
    fi
fi
echo
}

# 备份
function fuBACKUP () {
local myARCHIVE="/root/$(date +%Y%m%d%H%M)_moon_backup.tgz"
local myPATH=$PWD
echo "### 创建备份, 以防万一 ... "
echo -n "###### $myBLUE 创建在 $myARCHIVE $myWHITE"
cd /opt/moon
tar cvfz $myARCHIVE * 2>&1>/dev/null
if [ $? -ne 0 ];
  then
    echo " [ $myRED""错误""$myWHITE ]"
    echo "###### $myBLUE""出了一点问题.""$myWHITE"" [ $myRED""错误""$myWHITE ]"
    echo "退出.""$myWHITE"
    echo
    cd $myPATH
    exit 1
  else
    echo "[ $myGREEN"成功"$myWHITE ]"
    cd $myPATH
fi
echo
}

<<<<<<< HEAD
# 删除旧的镜像
=======
# Remove old images for specific tag
>>>>>>> origin/master
function fuREMOVEOLDIMAGES () {
local myOLDTAG=$1
local myOLDIMAGES=$(docker images | grep -c "$myOLDTAG")
if [ "$myOLDIMAGES" -gt "0" ];
  then
<<<<<<< HEAD
    echo "### 删除旧的Docker 镜像."
=======
    echo "### Removing old docker images."
>>>>>>> origin/master
    docker rmi $(docker images | grep "$myOLDTAG" | awk '{print $3}')
fi
}

<<<<<<< HEAD
# 加载Docker镜像
=======
# Let's load docker images in parallel
>>>>>>> origin/master
function fuPULLIMAGES {
local myMOONCOMPOSE="/opt/moon/etc/moon.yml"
for name in $(cat $myMOONCOMPOSE | grep -v '#' | grep image | cut -d'"' -f2 | uniq)
  do
    docker pull $name &
  done
wait
echo
}

function fuUPDATER () {
<<<<<<< HEAD
local myPACKAGES="apache2-utils apparmor apt-transport-https aufs-tools bash-completion build-essential ca-certificates cgroupfs-mount cockpit cockpit-docker curl debconf-utils dialog dnsutils docker.io docker-compose dstat ethtool fail2ban genisoimage git glances grc html2text htop ifupdown iptables iw jq libcrack2 libltdl7 lm-sensors man mosh multitail net-tools npm ntp openssh-server openssl pass prips software-properties-common syslinux psmisc pv python-pip unattended-upgrades unzip vim wireless-tools wpasupplicant"
echo "### 升级系统文件 ..."
=======
local myPACKAGES="apache2-utils apparmor apt-transport-https aufs-tools bash-completion build-essential ca-certificates cgroupfs-mount cockpit cockpit-docker curl debconf-utils  dialog dnsutils docker.io docker-compose dstat ethtool fail2ban genisoimage git glances grc html2text htop ifupdown iptables iw jq libcrack2 libltdl7 lm-sensors man mosh  multitail net-tools npm ntp openssh-server openssl pass prips software-properties-common syslinux psmisc pv python-pip unattended-upgrades unzip vim wireless-tools wpasupplicant"
echo "### Now upgrading packages ..."
>>>>>>> origin/master
dpkg --configure -a
apt-get -y autoclean
apt-get -y autoremove
apt-get update
apt-get -y install $myPACKAGES

<<<<<<< HEAD
# 一些更新会给出提示交互,将以下设置覆盖.
echo "docker.io docker.io/restart       boolean true" | debconf-set-selections -v
echo "debconf debconf/frontend select noninteractive" | debconf-set-selections -v
apt-get -y dist-upgrade -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --force-yes
=======
# Some updates require interactive attention, and the following settings will override that.
echo "docker.io docker.io/restart       boolean true" | debconf-set-selections -v
echo "debconf debconf/frontend select noninteractive" | debconf-set-selections -v
apt-get -y dist-upgrade -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --force-yes

>>>>>>> origin/master
dpkg --configure -a
npm install "https://gitee.com/stackw0rm/elasticsearch-dump.git" -g
pip install --upgrade pip
hash -r
pip install --upgrade elasticsearch-curator yq
cp iso/other/ctop-0.7.1-linux-amd64 -O /usr/bin/ctop && chmod +x /usr/bin/ctop
echo

echo "### 替换当前主机上的MoonStack配置文件"
cp host/etc/systemd/* /etc/systemd/system/
cp host/etc/issue /etc/
systemctl daemon-reload
echo

# 设置默认值
echo "### 设置MoonStack的文件夹,权限及默认设置."
sed -i 's#ListenStream=9090#ListenStream=64294#' /lib/systemd/system/cockpit.socket
sed -i '/^port/Id' /etc/ssh/sshd_config
echo "Port 64295" >> /etc/ssh/sshd_config
echo

### 创建与MoonStack相关的文件夹,以防万一
mkdir -p /data/adbhoney/downloads /data/adbhoney/log \
         /data/ciscoasa/log \
         /data/conpot/log \
         /data/cowrie/log/tty/ /data/cowrie/downloads/ /data/cowrie/keys/ /data/cowrie/misc/ \
         /data/dionaea/log /data/dionaea/bistreams /data/dionaea/binaries /data/dionaea/rtp /data/dionaea/roots/ftp /data/dionaea/roots/tftp /data/dionaea/roots/www /data/dionaea/roots/upnp \
         /data/elasticpot/log \
         /data/elk/data /data/elk/log \
         /data/glastopf/log /data/glastopf/db \
         /data/honeytrap/log/ /data/honeytrap/attacks/ /data/honeytrap/downloads/ \
         /data/glutton/log \
         /data/heralding/log \
         /data/mailoney/log \
         /data/medpot/log \
         /data/nginx/log \
         /data/emobility/log \
         /data/ews/conf \
         /data/rdpy/log \
         /data/spiderfoot \
         /data/suricata/log /home/msec/.ssh/ \
         /data/tanner/log /data/tanner/files \
         /data/p0f/log

### 设置文件和文件夹权限
chmod 760 -R /data
chown moon:moon -R /data
chmod 644 -R /data/nginx/conf
chmod 644 -R /data/nginx/cert

echo "### 现在获取最新的Docker镜像"
echo "######$myBLUE 这可能需要一段时间,请耐心等待!$myWHITE"
fuPULLIMAGES 2>&1>/dev/null

fuREMOVEOLDIMAGES "v1.1"
<<<<<<< HEAD
echo "### 如果你修改了moon.yml,请再次检查是否已经添加它们."
echo "### 我们将存储当前的版本在 /root/ 目录."
echo "### 已完成,请重启."
=======
echo "### If you made changes to moon.yml please ensure to add them again."
echo "### We stored the previous version as backup in /root/."
echo "### Done, please reboot."
>>>>>>> origin/master
echo
}


################
#   主要部分   #
################

# 获取Root权限
myWHOAMI=$(whoami)
if [ "$myWHOAMI" != "root" ]
  then
    echo "需要Root权限执行这个脚本 ..."
    sudo ./$0
    exit
fi

# 只使用命令开关执行
if [ "$1" != "-y" ]; then
  echo "这个脚本将升级与MoonStack相关的工具,脚本到最新版本."
  echo "正在运行的MoonStack的主目录 /opt/moon 将备份到 /root/ 目录下面.请注意保存备份当前正在运行的任务和状态."
  echo "这个升级目前还在测试中,只适用于有经验的用户."
  echo "如果你已经明白了我上面说的,并确定要升级,可以使用 -y 来执行升级操作."
  echo
  exit
fi

fuCHECK_VERSION
fuCONFIGCHECK
fuCHECKINET "https://index.docker.io https://gitee.com https://pypi.python.org "
fuSTOP_MOON
fuBACKUP
fuSELFUPDATE "$0" "$@"
fuUPDATER
