#!/bin/bash
# 默认只安装ogg基础服务，指定-installCloud参数，表示需要安装ogg微服务


# 创建用户组与oracle用户
if awk -F: '{print $1}' /etc/group | grep oinstall; then
  echo "oinstall用户组已存在"
else
  groupadd oinstall
  echo "oinstall用户组已创建"
fi

if awk -F: '{print $1}' /etc/group | grep dba; then
  echo "dba用户组已存在"
else
  groupadd dba
  echo "dba用户组已创建"
fi

if awk -F: '{print $1}' /etc/passwd | grep oracle; then
  echo "oracle用户已存在"
  usermod -g oinstall -G dba oracle
  echo "oracle所属用户组已修改"
else
  useradd -g oinstall -G dba -d /home/oracle oracle
  echo "oracle用户已创建"
fi


# 创建需要的目录
mkdir -p /oracle/app/ogg/db19.3/ogg191_ma
mkdir -p /oracle/app/ogg/db19.3/ogg191_sm
mkdir -p /oracle/app/ogg/db19.3/ogg191_deploy
echo "ogg相关目录已创建"

# 指定各个目录的所属用户与用户组
chown oracle:oinstall /oracle/app/ogg/db19.3/ogg191_ma
chown oracle:oinstall /oracle/app/ogg/db19.3/ogg191_sm
chown oracle:oinstall /oracle/app/ogg/db19.3/ogg191_deploy
echo "ogg相关目录所属用户与用户组已修改"

if [ ! -d /fbo_ggs_Linux_x64_Oracle_services_shiphome/Disk1/response ]; then
  echo "目录：/fbo_ggs_Linux_x64_Oracle_services_shiphome/Disk1/response 不存在，压缩包需要在根目录下解压。"
  exit 1
fi

cd /fbo_ggs_Linux_x64_Oracle_services_shiphome/Disk1/response

if [ -f oggcore.rsp ]; then
    mv -f oggcore.rsp oggcore_backup.rsp
fi

# 将内容写入文件
cat > oggcore.rsp <<EOF
oracle.install.responseFileVersion=/oracle/install/rspfmt_ogginstall_response_schema_v21_1_0
INSTALL_OPTION=ORA21c
SOFTWARE_LOCATION=/oracle/app/ogg/db19.3/ogg191_ma
START_MANAGER=false
MANAGER_PORT=Not applicable for a Services installation.
DATABASE_LOCATION=Not applicable for a Services installation.
INVENTORY_LOCATION=/oracle/app/oraInventory
UNIX_GROUP_NAME=oinstall
EOF

echo "oggcore.rsp文件写入成功"

# 用于校验runInstaller是否执行成功
mkdir -p /oracle/app/ogg/db19.3/check
chown oracle:oinstall /oracle/app/ogg/db19.3/check
su - oracle  <<!
cd /fbo_ggs_Linux_x64_Oracle_services_shiphome/Disk1
./runInstaller -silent -showProgress -responseFile /fbo_ggs_Linux_x64_Oracle_services_shiphome/Disk1/response/oggcore.rsp > /oracle/app/ogg/db19.3/check/runInstaller.log
if grep fail /oracle/app/ogg/db19.3/check/runInstaller.log; then
  echo "runInstaller安装失败"
else
  touch /oracle/app/ogg/db19.3/check/runInstaller.ok
fi
exit
!


#校验进程判断是否安装成功
if [ ! -f /oracle/app/ogg/db19.3/check/runInstaller.ok ]; then
  echo "runInstaller执行失败，终止后续操作, 日志请查看/oracle/app/ogg/db19.3/check/runInstaller.log"
  exit 1
fi

echo "runInstaller执行完毕,日志：/oracle/app/ogg/db19.3/check/runInstaller.log"

#是否需要安装微服务
installCloud="false"
for arg in $*
do
    if [ "$arg" = "-installCloud" ]; then
       installCloud="true"
    fi
    if [ $installCloud = "true" ]; then
       break;
    fi
done

if [ "$installCloud" = "false" ]; then
    echo "当前安装不需要安装ogg微服务"
    exit 1
fi

echo '127.0.0.1 oggms' >> /etc/hosts
echo "配置hosts文件完成"

cat > oggcloud.rsp <<EOF
oracle.install.responseFileVersion=/oracle/install/rspfmt_ogginstall_response_schema_v21_1_0
CONFIGURATION_OPTION=ADD
DEPLOYMENT_NAME=deploy19c
ADMINISTRATOR_USER=oggadmin
ADMINISTRATOR_PASSWORD=Tcdn@2007pcdb
SERVICEMANAGER_DEPLOYMENT_HOME=/oracle/app/ogg/db19.3/ogg191_sm
HOST_SERVICEMANAGER=oggms
PORT_SERVICEMANAGER=7809
SECURITY_ENABLED=false
CREATE_NEW_SERVICEMANAGER=true
REGISTER_SERVICEMANAGER_AS_A_SERVICE=true
INTEGRATE_SERVICEMANAGER_WITH_XAG=false
EXISTING_SERVICEMANAGER_IS_XAG_ENABLED=false
OGG_SOFTWARE_HOME=/oracle/app/ogg/db19.3/ogg191_ma
OGG_DEPLOYMENT_HOME=/oracle/app/ogg/db19.3/ogg191_deploy
OGG_ETC_HOME=
OGG_CONF_HOME=
OGG_SSL_HOME=
OGG_VAR_HOME=
OGG_DATA_HOME=
#ENV_ORACLE_HOME=/oracle/app/ogg/db19.3/ogg191_ma
#ENV_OGG_HOME=/oracle/app/ogg/db19.3/ogg191_ma
ENV_LD_LIBRARY_PATH=${OGG_HOME}/lib/instantclient:${OGG_HOME}/lib
ENV_TNS_ADMIN=/oracle/app/ogg/db19.3/tnsadmin
ENV_ORACLE_SID=
ENV_STREAMS_POOL_SIZE=
ENV_USER_VARS=
CIPHER_SUITES=
SERVER_WALLET=
SERVER_CERTIFICATE=
SERVER_CERTIFICATE_KEY_FILE=
SERVER_CERTIFICATE_KEY_FILE_PWD=
CLIENT_WALLET=
CLIENT_CERTIFICATE=
CLIENT_CERTIFICATE_KEY_FILE=
CLIENT_CERTIFICATE_KEY_FILE_PWD=
SHARDING_ENABLED=false
SHARDING_USER=
PORT_ADMINSRVR=8001
PORT_DISTSRVR=8002
NON_SECURE_DISTSRVR_CONNECTS_TO_SECURE_RCVRSRVR=false
PORT_RCVRSRVR=8003
METRICS_SERVER_ENABLED=true
METRICS_SERVER_IS_CRITICAL=false
PORT_PMSRVR=8004
UDP_PORT_PMSRVR=8005
PMSRVR_DATASTORE_TYPE=BDB
PMSRVR_DATASTORE_HOME=
OGG_SCHEMA=ogg
REMOVE_DEPLOYMENT_FROM_DISK=false
EOF


# 微服务静默安装
echo "开始安装微服务,日志：/oracle/app/ogg/db19.3/check/oggca.log"
su - oracle  << EOF
#export OGG_HOME=/oracle/app/ogg/db19.3/ogg191_ma
#export PATH=$PATH:$OGG_HOME/bin
/oracle/app/ogg/db19.3/ogg191_ma/bin/oggca.sh -silent -responseFile /fbo_ggs_Linux_x64_Oracle_services_shiphome/Disk1/response/oggcloud.rsp > /oracle/app/ogg/db19.3/check/oggca.log
if grep fail /oracle/app/ogg/db19.3/check/oggca.log; then
  echo "oggca安装失败"
elif grep 'not valid' /oracle/app/ogg/db19.3/check/oggca.log; then
  echo "oggca安装失败"
else
  touch /oracle/app/ogg/db19.3/check/oggca.ok
fi
exit

EOF

#校验进程判断是否安装成功
if [ ! -f /oracle/app/ogg/db19.3/check/oggca.ok ]; then
  echo "oggca执行失败，终止后续操作,日志请查看/oracle/app/ogg/db19.3/check/oggca.log"
  exit 1
fi

# 切回root用户，执行一个sh脚本
/oracle/app/ogg/db19.3/ogg191_sm/bin/registerServiceManager.sh
if [ $? = 0 ];then
  echo "微服务搭建成功"
fi
