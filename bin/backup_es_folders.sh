#!/bin/bash
#########################################
#    The MoonStack Backup ES by feng    # 
#########################################
# 备份所有 ElasticSearch 相关的文件夹
# 检测 ElasticSearch是否可用
myES="http://127.0.0.1:64298/"
myESSTATUS=$(curl -s -XGET ''$myES'_cluster/health' | jq '.' | grep -c green)
if ! [ "$myESSTATUS" = "1" ]
  then
    echo "### ElasticSearch 没有启动, 请使用 'systemctl start moon' 命令尝试启动."
    exit
  else
    echo "### ElasticSearch 已启动, 现在继续."
    echo
fi

# Set vars
myCOUNT=1
myDATE=$(date +%Y%m%d%H%M)
myELKPATH="/data/elk/data"
myKIBANAINDEXNAME=$(curl -s -XGET ''$myES'_cat/indices/' | grep -w ".kibana_1" | awk '{ print $4 }')
myKIBANAINDEXPATH=$myELKPATH/nodes/0/indices/$myKIBANAINDEXNAME

# 确保 ElasticSearch 是可用的,可以正常备份 ...
function fuCLEANUP {
  ### 启动 MoonStack
  systemctl start moon
  echo "### Starting MoonStack ..."
}
trap fuCLEANUP EXIT

# 停止 MoonStack 解锁数据库
echo "### Stoping MoonStack"
systemctl stop moon
sleep 2

# 两种方式备份数据库
echo "### Backup ElasticSearch files ..."
tar cvfz "elkall_"$myDATE".tgz" $myELKPATH
tar cvfz "elkbase_"$myDATE".tgz" $myKIBANAINDEXPATH
