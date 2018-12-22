#!/bin/bash
# MoonStack通用安装程序

#################
# 提取命令行参数 #
#################

myLSB=$(lsb_release -r | awk '{ print $2 }')
myLSB_SUPPORTED="18.04"
myINFO="\
############################################
### MoonStack安装基于 Ubuntu $myLSB_SUPPORTED LTS ###
############################################
免责声明：
此脚本将在此系统上安装 MoonStack, 您需要知道这个脚本会做哪些工作:
1. ssh 端口将重新配置为 tcp/64295
2. 一些软件包将被安装, 有些将被升级
3. 如有问题, 请确保可以使用其他方式访问本系统
4. 只能通过 ssh 会话在控制台上执行此脚本
###########################################

使用帮助:
        $0 --help - 帮助.

例如:
        $0 --type=user - 大多数用户的最佳选择."

if [ "$myLSB" != "$myLSB_SUPPORTED" ];
  then
    echo "该脚本意外终止. MoonStack安装脚本不支持当前 Ubuntu $myLSB 版本."
    exit
fi
if [ "$1" == "" ];
  then
    echo "$myINFO"
    exit
fi
for i in "$@"
  do
    case $i in
      --conf=*)
        myMOON_CONF_FILE="${i#*=}"
        shift
      ;;
      --type=user)
        myMOON_DEPLOYMENT_TYPE="${i#*=}"
        shift
      ;;
      --type=auto)
        myMOON_DEPLOYMENT_TYPE="${i#*=}"
        shift
      ;;
      --type=iso)
        myMOON_DEPLOYMENT_TYPE="${i#*=}"
        shift
      ;;
      --help)
        echo "Usage: $0 <options>"
        echo
        echo "--conf=<Path to \"moon.conf\">"
	      echo "  如果您需要自动部署 MoonStack 实例,请使用此选项 (--type=auto)."
        echo "  我们提供了一个配置文件示例 \"moon/iso/installer/moon.conf.dist\"."
        echo
        echo "--type=<[user, auto, iso]>"
        echo "  user 选项: 如果您需要手动安装 MoonStack 在 Ubuntu 18.04 LTS 上,请使用此选项."
        echo "  auto 选项: 如果使用配置文件作为自动部署参数传递,请使用此选项."
        echo "  iso  选项: 如果您是 MoonStack 开发人员,想要从预编译的 iso 安装 MoonStack ,请使用此选项."
        echo
	exit
      ;;
      *)
        echo "$myINFO"
	exit
      ;;
    esac
  done


########################
# 验证命令参数并加载配置 #
########################

# 如果存在有效的配置文件, 请将部署类型设置为 'auto' 并加载配置
if [ "$myMOON_DEPLOYMENT_TYPE" == "auto" ] && [ "$myMOON_CONF_FILE" == "" ];
  then
    echo "意外停止.未提供配置文件."
    exit
fi
if [ -s "$myMOON_CONF_FILE" ] && [ "$myMOON_CONF_FILE" != "" ];
  then
    myMOON_DEPLOYMENT_TYPE="auto"
    if [ "$(head -n 1 $myMOON_CONF_FILE | grep -c "# moon")" == "1" ];
      then
        source "$myMOON_CONF_FILE"
      else
	echo "意外停止. \"$myMOON_CONF_FILE\" 该配置文件不是 MoonStack 配置文件."
        exit
      fi
  elif ! [ -s "$myMOON_CONF_FILE" ] && [ "$myMOON_CONF_FILE" != "" ];
    then
      echo "意外停止. 在 \"$myMOON_CONF_FILE\" 位置没有找到配置文件."
      exit
fi


############
# 准备环境 #
###########

# 获取Root权限
function fuGOT_ROOT {
echo
echo -n "### 检查 Root 权限: "
if [ "$(whoami)" != "root" ];
  then
    echo "[ 错误 ]"
    echo "### 请使用 Root 权限运行."
    echo "### 用例: sudo $0"
    exit
  else
    echo "[ 成功 ]"
fi
}

# 检查所有依赖项
function fuGET_DEPS {
local myPACKAGES="apache2-utils apparmor apt-transport-https aufs-tools bash-completion build-essential ca-certificates cgroupfs-mount cockpit cockpit-docker curl debconf-utils dialog dnsutils docker.io docker-compose dstat ethtool fail2ban genisoimage git glances grc html2text htop ifupdown iptables iw jq libcrack2 libltdl7 lm-sensors man mosh multitail net-tools npm ntp openssh-server openssl pass prips software-properties-common syslinux psmisc pv python-pip unattended-upgrades unzip vim wireless-tools wpasupplicant"
echo
echo "### 备份 /etc/apt/source.list 到 /etc/apt/source.list.bak"
mv /etc/apt/sources.list /etc/apt/sources.list.bak
echo
echo "Write sources.list For mirrors.aliyun.com"
echo "deb https://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse" > /etc/apt/sources.list
echo "deb-src https://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb https://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb-src https://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb https://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb-src https://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb https://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb-src https://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse" >> /etc/apt/sources.list
echo
echo "### 开始更新系统."
echo
apt-get -y update
apt-get -y install software-properties-common
add-apt-repository "deb http://mirrors.aliyun.com/ubuntu $(lsb_release -sc) main universe restricted multiverse"
echo
echo "### 获取更新信息."
echo
apt-get -y update
echo
echo "### 获取更新软件包."
echo
# 下载和升级软件包,默认保留所有配置
echo "docker.io docker.io/restart       boolean true" | debconf-set-selections -v
echo "debconf debconf/frontend select noninteractive" | debconf-set-selections -v
apt-get -y dist-upgrade -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --force-yes
echo
echo "### 安装 MoonStack 依赖."
echo
apt-get -y install $myPACKAGES
}

# 加载对话框主题
function fuDIALOG_SETUP {
echo
echo -n "### 检查 dialogrc 文件: "
if [ -f "dialogrc" ];
  then
    echo "[ 完成 ]"
    cp dialogrc /etc/
  else
    echo "[ 错误 ]"
    echo "###加载 'dialogrc' 文件错误. 请在安装目录运行 'install.sh' 脚本."
    exit
  fi
}

# 检查其他服务
function fuCHECK_PORTS {
if [ "$myMOON_DEPLOYMENT_TYPE" == "user" ];
  then
    echo
    echo "### 检查正在运行的服务."
    echo
    grc netstat -tulpen
    echo
    echo "### 请查看您正在运行的服务."
    echo "### MoonStack 将修改 SSH (22) 端口, 但是其他服务,例如: FTP (21), TELNET (23), SMTP (25), HTTP (80), HTTPS (443), etc."
    echo "### 可能会与 MoonStack 蜜罐冲突, 导致 MoonStack 无法正常启动."
    echo
    while [ 1 != 2 ]
      do
        read -s -n 1 -p "继续 [y/n]? " mySELECT
	echo
        case "$mySELECT" in
          [y,Y])
            break
            ;;
          [n,N])
            exit
            ;;
        esac
      done
fi
}


# 准备运行安装程序
echo "$myINFO" | head -n 3
fuGOT_ROOT
fuGET_DEPS
fuCHECK_PORTS
fuDIALOG_SETUP


############
# 安装程序 #
############

# 设置 TERM, DIALOGRC
export TERM=linux
export DIALOGRC=/etc/dialogrc

###############
# 全局变量设置 #
###############

myBACKTITLE="MoonStack 安装程序"
myCONF_FILE="/root/installer/iso.conf"
myPROGRESSBOXCONF=" --backtitle "$myBACKTITLE" --progressbox 24 80"
mySITES="https://hub.docker.com https://gitee.com https://pypi.python.org https://ubuntu.com"
myMOONCOMPOSE="/opt/moon/etc/moon.yml"

############
# 功能函数 #
###########

fuRANDOMWORD () {
  local myWORDFILE="$1"
  local myLINES=$(cat $myWORDFILE  | wc -l)
  local myRANDOM=$((RANDOM % $myLINES))
  local myNUM=$((myRANDOM * myRANDOM % $myLINES + 1))
  echo -n $(sed -n "$myNUM p" $myWORDFILE | tr -d \' | tr A-Z a-z)
}

# 如果这是ISO安装,请等待几秒钟,避免干扰服务消息
if [ "$myMOON_DEPLOYMENT_TYPE" == "iso" ];
  then
    sleep 5
    tput civis
    dialog --no-ok --no-cancel --backtitle "$myBACKTITLE" --title "[ 等待几秒钟, 避免干扰服务消息 ]" --pause "" 6 80 7
fi

# 如果有 ISO 配置文件,则加载
if [ -f $myCONF_FILE ];
  then
    dialog --backtitle "$myBACKTITLE" --title "[ 找到 iso.config 配置文件 ]" --msgbox "\n该配置文件将被应用!" 7 47
    source $myCONF_FILE
  else
    # 对话框逻辑 1=false, 0=true
    myCONF_PROXY_USE="1"
    myCONF_PFX_USE="1"
    myCONF_NTP_USE="1"
fi


### <--- 使用代理方式安装
# 如果在 iso.config 中使用了代理, 则需要对其进行设置.
# 但是, 其他安装类型都不会自动处理代理设置.
# 如果需要再考虑一下, 请打开一个功能请求.
myPROXY="http://$myCONF_PROXY_IP:$myCONF_PROXY_PORT"
myPROXY_ENV="export http_proxy=$myPROXY
export https_proxy=$myPROXY
export HTTP_PROXY=$myPROXY
export HTTPS_PROXY=$myPROXY
export no_proxy=localhost,127.0.0.1,.sock
"
myPROXY_APT="Acquire::http::Proxy \"$myPROXY\";
Acquire::https::Proxy \"$myPROXY\";
"
myPROXY_DOCKER="http_proxy=$myPROXY
https_proxy=$myPROXY
HTTP_PROXY=$myPROXY
HTTPS_PROXY=$myPROXY
no_proxy=localhost,127.0.0.1,.sock
"

if [ "$myCONF_PROXY_USE" == "0" ];
  then
    # 为环境设置代理
    echo "$myPROXY_ENV" 2>&1 | tee -a /etc/environment | dialog --title "[ 正在为 environment 设置代理 ]" $myPROGRESSBOXCONF
    source /etc/environment

    # 为 apt 设置代理
    echo "$myPROXY_APT" 2>&1 | tee /etc/apt/apt.conf | dialog --title "[ 正在为 apt 设置代理 ]" $myPROGRESSBOXCONF

    # 为 docker 设置代理
    echo "$myPROXY_DOCKER" 2>&1 | tee -a /etc/default/docker | dialog --title "[ 正在为 docker 设置代理 ]" $myPROGRESSBOXCONF

    # 重新启动 docker 使代理生效
    systemctl stop docker 2>&1 | dialog --title "[ 停止 docker 服务 ]" $myPROGRESSBOXCONF
    systemctl start docker 2>&1 | dialog --title "[ 启动 docker 服务 ]" $myPROGRESSBOXCONF
fi
### ---> 代理安装结束

# 测试互联网连接
if [ "$myMOON_DEPLOYMENT_TYPE" == "iso" ] || [ "$myMOON_DEPLOYMENT_TYPE" == "user" ];
  then
    mySITESCOUNT=$(echo $mySITES | wc -w)
    j=0
    for i in $mySITES;
      do
        curl --connect-timeout 30 -IsS $i 2>&1>/dev/null | dialog --title "[ 正在检测互联网连接 ]" --backtitle "$myBACKTITLE" \
                                                                  --gauge "\n  现在检测: $i\n" 8 80 $(expr 100 \* $j / $mySITESCOUNT)
        if [ $? -ne 0 ];
          then
            dialog --backtitle "$myBACKTITLE" --title "[ 继续? ]" --yesno "\n互联网连接检测失败. 这表示您的互联网连接存在一些问题. 您可以继续, 但可能会安装失败." 10 50
            if [ $? = 1 ];
              then
                dialog --backtitle "$myBACKTITLE" --title "[ 意外终止 ]" --msgbox "\n安装意外终止, 退出安装程序." 7 50
                exit
              else
                break;
            fi;
        fi;
      let j+=1
      echo 2>&1>/dev/null | dialog --title "[ 检测互联网连接 ]" --backtitle "$myBACKTITLE" \
                                                                                 --gauge "\n  现在检测: $i\n" 8 80 $(expr 100 \* $j / $mySITESCOUNT)
    done;
fi
# 以标准形式将光标放回原处
tput cnorm

############
# 用户交互 #
############

# 向用户询问安装风格
if [ "$myMOON_DEPLOYMENT_TYPE" == "iso" ] || [ "$myMOON_DEPLOYMENT_TYPE" == "user" ];
  then
    myCONF_MOON_FLAVOR=$(dialog --no-cancel --backtitle "$myBACKTITLE" --title "[ 选择需要安装的 MoonStack 风格 ]" --menu \
    "\n基本配置: 6GB RAM, 128GB SSD\n推荐配置: 8GB RAM, 256GB SSD" 15 70 7 \
    "STANDARD" "标准安装: 蜜罐, ELK, 识别引擎 & 工具" \
    "SENSOR" "传感器: 只有(Ews, Poster)蜜罐 & 识别引擎" \
    "INDUSTRIAL" "工控场景: 只有(Conpot, RDPY, Vnclowpot)蜜罐 ELK, 识别引擎 & 工具" \
    "COLLECTOR" "采集场景: Heralding, ELK, 识别引擎 & 工具" \
    "NEXTGEN" "下一代蜜网: Glutton 而不是传统蜜罐" \
    "LEGACY" "标准版(旧): 之前版本中的标准版" 3>&1 1>&2 2>&3 3>&-)
fi

# 如果安装类型为ISO, 则我们需要用户输入一个msec的密码
if [ "$myMOON_DEPLOYMENT_TYPE" == "iso" ];
  then
    myCONF_MOON_USER="msec"
    myPASS1="pass1"
    myPASS2="pass2"
    mySECURE="0"
    while [ "$myPASS1" != "$myPASS2"  ] && [ "$mySECURE" == "0" ]
      do
        while [ "$myPASS1" == "pass1"  ] || [ "$myPASS1" == "" ]
          do
            myPASS1=$(dialog --insecure --backtitle "$myBACKTITLE" \
                             --title "[ 请输入控制台用户 msec 的密码]" \
                             --passwordbox "\n密码" 9 60 3>&1 1>&2 2>&3 3>&-)
          done
            myPASS2=$(dialog --insecure --backtitle "$myBACKTITLE" \
                             --title "[ 请再输入一次控制台用户 msec 的密码 ]" \
                             --passwordbox "\n密码" 9 60 3>&1 1>&2 2>&3 3>&-)
        if [ "$myPASS1" != "$myPASS2" ];
          then
            dialog --backtitle "$myBACKTITLE" --title "[ 您输入的密码不匹配. ]" \
                   --msgbox "\n请重新输入控制台用户 msec 的密码." 7 60
            myPASS1="pass1"
            myPASS2="pass2"
        fi
        mySECURE=$(printf "%s" "$myPASS1" | cracklib-check | grep -c "OK")
        if [ "$mySECURE" == "0" ] && [ "$myPASS1" == "$myPASS2" ];
          then
            dialog --backtitle "$myBACKTITLE" --title "[ 您输入的密码不安全 ]" --defaultno --yesno "\n继续使用不安全的密码?" 7 50
            myOK=$?
            if [ "$myOK" == "1" ];
              then
                myPASS1="pass1"
                myPASS2="pass2"
            fi
        fi
      done
    printf "%s" "$myCONF_MOON_USER:$myPASS1" | chpasswd
fi

# 在 ISO 安装模式下,我们则需要用户输入一个用于web用户的登陆户凭证
# 如果是 auto 安装模式, 这个web用户的登陆凭证将从配置创建
# 如果安装为 传感器 则跳过这个凭证
if [ "$myMOON_DEPLOYMENT_TYPE" == "iso" ] || [ "$myMOON_DEPLOYMENT_TYPE" == "user" ];
  then
    myOK="1"
    myCONF_WEB_USER="webuser"
    myCONF_WEB_PW="pass1"
    myCONF_WEB_PW2="pass2"
    mySECURE="0"
    while [ 1 != 2 ]
      do
        myCONF_WEB_USER=$(dialog --backtitle "$myBACKTITLE" --title "[ 请输入用于 web 的用户名 ]" --inputbox "\n用户名 (不允许使用 msec)" 9 50 3>&1 1>&2 2>&3 3>&-)
        myCONF_WEB_USER=$(echo $myCONF_WEB_USER | tr -cd "[:alnum:]_.-")
        dialog --backtitle "$myBACKTITLE" --title "[ 确认这个用户名 ]" --yesno "\n$myCONF_WEB_USER" 7 50
        myOK=$?
        if [ "$myOK" = "0" ] && [ "$myCONF_WEB_USER" != "msec" ] && [ "$myCONF_WEB_USER" != "" ];
          then
            break
        fi
      done
    while [ "$myCONF_WEB_PW" != "$myCONF_WEB_PW2"  ] && [ "$mySECURE" == "0" ]
      do
        while [ "$myCONF_WEB_PW" == "pass1"  ] || [ "$myCONF_WEB_PW" == "" ]
          do
            myCONF_WEB_PW=$(dialog --insecure --backtitle "$myBACKTITLE" \
                             --title "[ 请输入您的 web 用户密码 ]" \
                             --passwordbox "\n密码" 9 60 3>&1 1>&2 2>&3 3>&-)
          done
        myCONF_WEB_PW2=$(dialog --insecure --backtitle "$myBACKTITLE" \
                         --title "[ 请再输入一次您的 web 用户密码 ]" \
                         --passwordbox "\n密码" 9 60 3>&1 1>&2 2>&3 3>&-)
        if [ "$myCONF_WEB_PW" != "$myCONF_WEB_PW2" ];
          then
            dialog --backtitle "$myBACKTITLE" --title "[ 密码不匹配. ]" \
                   --msgbox "\n请重新输入您的 web 用户密码." 7 60
            myCONF_WEB_PW="pass1"
            myCONF_WEB_PW2="pass2"
        fi
        mySECURE=$(printf "%s" "$myCONF_WEB_PW" | cracklib-check | grep -c "OK")
        if [ "$mySECURE" == "0" ] && [ "$myCONF_WEB_PW" == "$myCONF_WEB_PW2" ];
          then
            dialog --backtitle "$myBACKTITLE" --title "[ 密码不安全 ]" --defaultno --yesno "\n您确定使用这个不安全的密码?" 7 50
            myOK=$?
            if [ "$myOK" == "1" ];
              then
                myCONF_WEB_PW="pass1"
                myCONF_WEB_PW2="pass2"
            fi
        fi
      done
fi
# 如果只是安装的风格是传感器, 则不产生 Web凭证
if ! [ "$myCONF_MOON_FLAVOR" == "SENSOR" ];
  then
    mkdir -p /data/nginx/conf 2>&1
    htpasswd -b -c /data/nginx/conf/nginxpasswd "$myCONF_WEB_USER" "$myCONF_WEB_PW" 2>&1 | dialog --title "[ 设置用户名和密码 ]" $myPROGRESSBOXCONF;
fi


############
# 安装部分 #
############

# 将光标隐藏
tput civis

# 生成一个SSL证书, 但这种方式下, 浏览器无论如何都会认为它无效
if ! [ "$myCONF_MOON_FLAVOR" == "SENSOR" ];
then
mkdir -p /data/nginx/cert 2>&1 | dialog --title "[ 为 NGINX 生成一个自签名证书 ]" $myPROGRESSBOXCONF;
openssl req \
        -nodes \
        -x509 \
        -sha512 \
        -newkey rsa:8192 \
        -keyout "/data/nginx/cert/nginx.key" \
        -out "/data/nginx/cert/nginx.crt" \
        -days 3650 \
        -subj '/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd' 2>&1 | dialog --title "[ 为 NGINX 生成一个自签名证书 ]" $myPROGRESSBOXCONF;
fi

# 设置 ntp 服务器
if [ "$myCONF_NTP_USE" == "0" ];
  then
    cp $myCONF_NTP_CONF_FILE /etc/ntp.conf 2>&1 | dialog --title "[ 设置 ntp 时间服务器 ]" $myPROGRESSBOXCONF
fi

# 设置 802.1x 网络
myNETWORK_INTERFACES="
wpa-driver wired
wpa-conf /etc/wpa_supplicant/wired8021x.conf

### 无线网络 802.1x 配置示例
### 此配置通过 IntelNUC 系列测试
### 如果出现问题, 您可以尝试将 wpa 驱动程序更改为: \"iwlwifi\"
### 不要忘了在 /etc/wpa_supplicant/wireless8021x.conf 输入对应的 ssid
### 在Intel NUC 中,使用 wlpXsY 表示无线网络,而不是 wlanX
#
#auto wlp2s0
#iface wlp2s0 inet dhcp
#        wpa-driver wext
#        wpa-conf /etc/wpa_supplicant/wireless8021x.conf
"
myNETWORK_WIRED8021x="ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=root
eapol_version=1
ap_scan=1
network={
  key_mgmt=IEEE8021X
  eap=TLS
  identity=\"host/$myCONF_PFX_HOST_ID\"
  private_key=\"/etc/wpa_supplicant/8021x.pfx\"
  private_key_passwd=\"$myCONF_PFX_PW\"
}
"
myNETWORK_WLAN8021x="ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=root
eapol_version=1
ap_scan=1
network={
  ssid=\"<请在这里输入 无线网络名称(ssid) 不带括号>\"
  key_mgmt=WPA-EAP
  pairwise=CCMP
  group=CCMP
  eap=TLS
  identity=\"host/$myCONF_PFX_HOST_ID\"
  private_key=\"/etc/wpa_supplicant/8021x.pfx\"
  private_key_passwd="$myCONF_PFX_PW"
}
"
if [ "myCONF_PFX_USE" == "0" ];
  then
    cp $myCONF_PFX_FILE /etc/wpa_supplicant/ 2>&1 | dialog --title "[ 设置 802.1x 网络 ]" $myPROGRESSBOXCONF
    echo "$myNETWORK_INTERFACES" 2>&1 | tee -a /etc/network/interfaces | dialog --title "[ 设置 802.1x 网络 ]" $myPROGRESSBOXCONF

    echo "$myNETWORK_WIRED8021x" 2>&1 | tee /etc/wpa_supplicant/wired8021x.conf | dialog --title "[ 设置 802.1x 网络 ]" $myPROGRESSBOXCONF

    echo "$myNETWORK_WLAN8021x" 2>&1 | tee /etc/wpa_supplicant/wireless8021x.conf | dialog --title "[ 设置 802.1x 网络 ]" $myPROGRESSBOXCONF
fi

# 我们提供一个无限配置示例 ...
myNETWORK_WLANEXAMPLE="
### 静态 IP 配置示例
### 替换 <eth0> 为您实际的物理网络接口的名称
#
#auto eth0
#iface eth0 inet static
# address 192.168.1.1
# netmask 255.255.255.0
# network 192.168.1.0
# broadcast 192.168.1.255
# gateway 192.168.1.1
# dns-nameservers 192.168.1.1

### 无线网络配置示例, 不含 802.1x
### 此配置通过 IntelNUC 系列测试
### 如果出现问题, 您可以尝试将 wpa 驱动程序更改为: \"iwlwifi\"
#
#auto wlan0
#iface wlan0 inet dhcp
#   wpa-driver wext
#   wpa-ssid <请在这里输入 无线网络名称(ssid) 不带括号>
#   wpa-ap-scan 1
#   wpa-proto RSN
#   wpa-pairwise CCMP
#   wpa-group CCMP
#   wpa-key-mgmt WPA-PSK
#   wpa-psk \"<请在这里输入 无线网络密码 不带括号>\"
"
echo "$myNETWORK_WLANEXAMPLE" 2>&1 | tee -a /etc/network/interfaces | dialog --title "[ WLAN 配置示例 ]" $myPROGRESSBOXCONF

# 修改 sources.list
sed -i '/cdrom/d' /etc/apt/sources.list

# 确保 SSH roaming 已经关闭(CVE-2016-0777, CVE-2016-0778)
echo "UseRoaming no" 2>&1 | tee -a /etc/ssh/ssh_config | dialog --title "[ SSH Roaming 已经关闭 ]" $myPROGRESSBOXCONF

# 安装 ctop, elasticdump, moon, yq
npm install https://gitee.com/stackw0rm/elasticsearch-dump.git -g 2>&1 | dialog --title "[ 安装 elasticsearch-dump ]" $myPROGRESSBOXCONF
pip install --upgrade pip 2>&1 | dialog --title "[ 安装 pip ]" $myPROGRESSBOXCONF
hash -r 2>&1 | dialog --title "[ 安装 pip ]" $myPROGRESSBOXCONF
pip install elasticsearch-curator yq 2>&1 | dialog --title "[ 安装 elasticsearch-curator, yq ]" $myPROGRESSBOXCONF
git clone https://gitee.com/stackw0rm/moon.git -b v1.2 /opt/moon 2>&1 | dialog --title "[ 克隆 MoonStack ]" $myPROGRESSBOXCONF
cp /opt/moon/iso/other/ctop-0.7.1-linux-amd64 -O /usr/bin/ctop 2>&1 | dialog --title "[ 安装 ctop ]" $myPROGRESSBOXCONF
chmod +x /usr/bin/ctop 2>&1 | dialog --title "[ 安装 ctop ]" $myPROGRESSBOXCONF
/opt/moon/iso/installer/set_mirrors.sh https://0at6ledb.mirror.aliyuncs.com 2>&1 | dialog --title "[ 设置 Aliyun Docker 镜像加速器 ]" $myPROGRESSBOXCONF
systemctl daemon-reload 2>&1 | dialog --title "[ 重新载入 Daemon ]" $myPROGRESSBOXCONF
systemctl restart  docker 2>&1 | dialog --title "[ 重启 Docker 服务 ]" $myPROGRESSBOXCONF

# 创建 MoonStack 用户及组
addgroup --gid 2000 moon 2>&1 | dialog --title "[ 创建 moon 用户组 ]" $myPROGRESSBOXCONF
adduser --system --no-create-home --uid 2000 --disabled-password --disabled-login --gid 2000 moon 2>&1 | dialog --title "[ 创建 moon 用户 ]" $myPROGRESSBOXCONF

# 设置 hostname
a=$(fuRANDOMWORD /opt/moon/host/usr/share/dict/a.txt)
n=$(fuRANDOMWORD /opt/moon/host/usr/share/dict/n.txt)
myHOST=$a$n
hostnamectl set-hostname $myHOST 2>&1 | dialog --title "[ 设置新的 hostname ]" $myPROGRESSBOXCONF
sed -i 's#127.0.1.1.*#127.0.1.1\t'"$myHOST"'#g' /etc/hosts 2>&1 | dialog --title "[ 设置新的hostname ]" $myPROGRESSBOXCONF
if [ -f "/etc/cloud/cloud.cfg" ];
  then
    sed -i 's/preserve_hostname: false/preserve_hostname: true/' /etc/cloud/cloud.cfg
fi

# 修改 cockpit.socket, sshd_config
sed -i 's#ListenStream=9090#ListenStream=64294#' /lib/systemd/system/cockpit.socket 2>&1 | dialog --title "[ Cockpit 端口修改为 tcp/64294 ]" $myPROGRESSBOXCONF
sed -i '/^port/Id' /etc/ssh/sshd_config 2>&1 | dialog --title "[ SSH 端口修改为 tcp/64295 ]" $myPROGRESSBOXCONF
echo "Port 64295" >> /etc/ssh/sshd_config 2>&1 | dialog --title "[ SSH 端口修改为 tcp/64295 ]" $myPROGRESSBOXCONF

# 确保只有一个配置被启动
case $myCONF_MOON_FLAVOR in
  STANDARD)
    echo "### 即将执行 STANDARD (标准模式)安装."
    ln -s /opt/moon/etc/compose/standard.yml $myMOONCOMPOSE 2>&1>/dev/null
  ;;
  SENSOR)
    echo "### 即将执行 SENSOR (传感器)安装."
    ln -s /opt/moon/etc/compose/sensor.yml $myMOONCOMPOSE 2>&1>/dev/null
  ;;
  INDUSTRIAL)
    echo "### 即将执行 INDUSTRIAL (工控场景)安装."
    ln -s /opt/moon/etc/compose/industrial.yml $myMOONCOMPOSE 2>&1>/dev/null
  ;;
  COLLECTOR)
    echo "### 即将执行 COLLECTOR (采集场景)安装."
    ln -s /opt/moon/etc/compose/collector.yml $myMOONCOMPOSE 2>&1>/dev/null
  ;;
  NEXTGEN)
    echo "### 即将执行 NEXTGEN (下一代蜜网)安装."
    ln -s /opt/moon/etc/compose/nextgen.yml $myMOONCOMPOSE 2>&1>/dev/null
  ;;
  LEGACY)
    echo "### 即将执行 LEGACY (标准版(旧)安装."
    ln -s /opt/moon/etc/compose/legacy.yml $myMOONCOMPOSE 2>&1>/dev/null
  ;;
esac

# 加载 docker 镜像
function fuPULLIMAGES {
for name in $(cat $myMOONCOMPOSE | grep -v '#' | grep image | cut -d'"' -f2 | uniq)
  do
    docker pull $name &
done
wait
}
fuPULLIMAGES 2>&1 | dialog --title "[ 正在获取Docker镜像, 请耐心等待 ]" $myPROGRESSBOXCONF

# 设置检查更新 为每周
myUPDATECHECK="APT::Periodic::Update-Package-Lists \"1\";
APT::Periodic::Download-Upgradeable-Packages \"0\";
APT::Periodic::AutocleanInterval \"7\";
"
echo "$myUPDATECHECK" 2>&1 | tee /etc/apt/apt.conf.d/10periodic | dialog --title "[ 修改更新检查 ]" $myPROGRESSBOXCONF

# 确保内核崩溃后系统可以重新启动
mySYSCTLCONF="
# 通过设置 /proc/sys/kernel/panic[_on_oops], 确保内核崩溃后系统重新启动
# 设置 ELK 所需的 map_count
kernel.panic = 1
kernel.panic_on_oops = 1
vm.max_map_count = 262144
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
"
echo "$mySYSCTLCONF" 2>&1 | tee -a /etc/sysctl.conf | dialog --title "[ 调整 Sysctl ]" $myPROGRESSBOXCONF

# 设置 fail2ban
myFAIL2BANCONF="[DEFAULT]
ignore-ip = 127.0.0.1/8
bantime = 3600
findtime = 600
maxretry = 5

[nginx-http-auth]
enabled  = true
filter   = nginx-http-auth
port     = 64297
logpath  = /data/nginx/log/error.log

[pam-generic]
enabled = true
port    = 64294
filter  = pam-generic
logpath = /var/log/auth.log

[sshd]
enabled = true
port    = 64295
filter  = sshd
logpath = /var/log/auth.log
"
echo "$myFAIL2BANCONF" 2>&1 | tee /etc/fail2ban/jail.d/moon.conf | dialog --title "[ 设置 fail2ban ]" $myPROGRESSBOXCONF

# 修改 systemd 错误 https://github.com/systemd/systemd/issues/3374
mySYSTEMDFIX="[Link]
NamePolicy=kernel database onboard slot path
MACAddressPolicy=none
"
echo "$mySYSTEMDFIX" 2>&1 | tee /etc/systemd/network/99-default.link | dialog --title "[ 修改 systemd 错误 ]" $myPROGRESSBOXCONF

# 添加一些 cron 作业
myCRONJOBS="
# 检查到新的 docker 镜像后下载
27 1 * * *      root    docker-compose -f /opt/moon/etc/moon.yml pull

# 90天自动清空 elasticsearch logstash 文件夹
27 4 * * *      root    curator --config /opt/moon/etc/curator/curator.yml /opt/moon/etc/curator/actions.yml

# 上传的二进制文件不能下载
*/1 * * * *     root    mv --backup=numbered /data/dionaea/roots/ftp/* /data/dionaea/binaries/

# 每天重新启动
27 3 * * *      root    systemctl stop moon && docker stop \$(docker ps -aq) || docker rm \$(docker ps -aq) || reboot

# 每周日检查升级的软件包, 自动下载并重新启动
27 16 * * 0     root    apt-get autoclean -y && apt-get autoremove -y && apt-get update -y && apt-get upgrade -y && sleep 10 && reboot
"
echo "$myCRONJOBS" 2>&1 | tee -a /etc/crontab | dialog --title "[ 添加 cron 任务 ]" $myPROGRESSBOXCONF

# 创建一些文件和文件夹
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
         /data/p0f/log 2>&1 | dialog --title "[ 创建一些文件和文件夹 ]" $myPROGRESSBOXCONF
touch /data/spiderfoot/spiderfoot.db 2>&1 | dialog --title "[ 创建一些文件和文件夹 ]" $myPROGRESSBOXCONF
touch /data/nginx/log/error.log  2>&1 | dialog --title "[ 创建一些文件和文件夹 ]" $myPROGRESSBOXCONF

# 拷贝一些文件
tar xvfz /opt/moon/etc/objects/elkbase.tgz -C / 2>&1 | dialog --title "[ 解压缩 elkbase.tgz ]" $myPROGRESSBOXCONF
cp /opt/moon/host/etc/systemd/* /etc/systemd/system/ 2>&1 | dialog --title "[ 复制配置文件 ]" $myPROGRESSBOXCONF
cp /opt/moon/host/etc/issue /etc/ 2>&1 | dialog --title "[ 复制配置文件 ]" $myPROGRESSBOXCONF
systemctl enable moon 2>&1 | dialog --title "[ 开启 moon 服务 ]" $myPROGRESSBOXCONF

# 处理一些文件和权限
chmod 760 -R /data 2>&1 | dialog --title "[ 设置权限和所属权限 ]" $myPROGRESSBOXCONF
chown moon:moon -R /data 2>&1 | dialog --title "[ 设置权限和所属权限 ]" $myPROGRESSBOXCONF
chmod 644 -R /data/nginx/conf 2>&1 | dialog --title "[ 设置权限和所属权限 ]" $myPROGRESSBOXCONF
chmod 644 -R /data/nginx/cert 2>&1 | dialog --title "[ 设置权限和所属权限 ]" $myPROGRESSBOXCONF

# 替换 "quiet splash" 选项, 设置更多的屏幕风格, 并写入grub
sed -i 's#GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"#GRUB_CMDLINE_LINUX_DEFAULT="consoleblank=0"#' /etc/default/grub 2>&1>/dev/null
sed -i 's#GRUB_CMDLINE_LINUX=""#GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"#' /etc/default/grub 2>&1>/dev/null
update-grub 2>&1 | dialog --title "[ 更新 grub ]" $myPROGRESSBOXCONF
cp /usr/share/consolefonts/Uni2-Terminus12x6.psf.gz /etc/console-setup/
gunzip /etc/console-setup/Uni2-Terminus12x6.psf.gz
sed -i 's#FONTFACE=".*#FONTFACE="Terminus"#' /etc/default/console-setup
sed -i 's#FONTSIZE=".*#FONTSIZE="12x6"#' /etc/default/console-setup
update-initramfs -u 2>&1 | dialog --title "[ 更新 initramfs ]" $myPROGRESSBOXCONF

# 启用颜色提示, 并将 /opt/moon/bin 写入用户变量
myROOTPROMPT='PS1="\[\033[38;5;8m\][\[$(tput sgr0)\]\[\033[38;5;1m\]\u\[$(tput sgr0)\]\[\033[38;5;6m\]@\[$(tput sgr0)\]\[\033[38;5;4m\]\h\[$(tput sgr0)\]\[\033[38;5;6m\]:\[$(tput sgr0)\]\[\033[38;5;5m\]\w\[$(tput sgr0)\]\[\033[38;5;8m\]]\[$(tput sgr0)\]\[\033[38;5;1m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"'
myUSERPROMPT='PS1="\[\033[38;5;8m\][\[$(tput sgr0)\]\[\033[38;5;2m\]\u\[$(tput sgr0)\]\[\033[38;5;6m\]@\[$(tput sgr0)\]\[\033[38;5;4m\]\h\[$(tput sgr0)\]\[\033[38;5;6m\]:\[$(tput sgr0)\]\[\033[38;5;5m\]\w\[$(tput sgr0)\]\[\033[38;5;8m\]]\[$(tput sgr0)\]\[\033[38;5;2m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"'
tee -a /root/.bashrc 2>&1>/dev/null <<EOF
$myROOTPROMPT
PATH="$PATH:/opt/moon/bin"
EOF
for i in $(ls -d /home/*/)
  do
tee -a $i.bashrc 2>&1>/dev/null <<EOF
$myUSERPROMPT
PATH="$PATH:/opt/moon/bin"
EOF
done

# 在重新启动之前设置 ews.ip
/opt/moon/bin/updateip.sh 2>&1>/dev/null

# 清理 apt
apt-get autoclean -y 2>&1 | dialog --title "[ apt清理 ]" $myPROGRESSBOXCONF
apt-get autoremove -y 2>&1 | dialog --title "[ apt自动卸载过期软件包 ]" $myPROGRESSBOXCONF

# 最后步骤
cp /opt/moon/host/etc/rc.local /etc/rc.local 2>&1>/dev/null && \
rm -rf /root/installer 2>&1>/dev/null && \
if [ "$myMOON_DEPLOYMENT_TYPE" == "auto" ];
  then
    echo "完成. 请重启."
  else
    dialog --no-ok --no-cancel --backtitle "$myBACKTITLE" --title "[ 感谢您的耐心等待, 即将重新启动. ]" --pause "" 6 80 2 && \
    reboot
fi
