#!/bin/bash
#openstack rocky版本，控制节点环境准备

#####网络参数变量

export controller_ip=192.168.20.53
export compute01_ip=192.168.20.54


#####显示边框

function sw(){
echo "#############################################"
echo "$1"
echo "#############################################"
echo ""
echo ""
sleep 10s
}

###############################################
##                                            #
##          控制节点操作环境准备              #   
##                                            #  
###############################################


#####主机名

sw 'SHOTNAME'
hostnamectl set-hostname controller
export HOSTNAME=controller


#####主机名解析

sw 'HOSTNAME RESOLVE'
echo 10.0.0.11 controller >> /etc/hosts
echo 10.0.0.12 compute01 >> /etc/hosts
sed -i "s/10.0.0.11/$controller_ip/g" /etc/hosts
sed -i "s/10.0.0.12/$compute01_ip/g" /etc/hosts


#####网络配置(略)


#####firewalld和selinux

sw 'STOP & DISABLE FIREWALLD AND SELINUX'
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

#####时间同步

sw 'NTP SET UP'
yum install chrony -y

###########时间同步方案一，控制节点同步外网，其他节点同步控制节点
#sed -i '3s/0.centos.pool.ntp.org/ntp1.aliyun.com/g' /etc/chrony.conf
#sed -i '4s/1.centos.pool.ntp.org/ntp1.aliyun.com/g' /etc/chrony.conf
#sed -i '5,6s/^/#/g' /etc/chrony.conf
###########时间同步方案二，控制节点不同步外网，其他节点同步控制节点
sed -i '3,6s/^/#/g' /etc/chrony.conf
sed -i "s/#allow 192.168.0.0/allow 192.168.0.0/g" /etc/chrony.conf
sed -i 's/#local stratum 10/local stratum 10/g' /etc/chrony.conf
systemctl restart chronyd
systemctl enable chronyd


#####安装配置yum源

sw 'CONFIGE YUM REPO'
yum install centos-release-openstack-rocky -y

#####更新软件包

sw 'UPGRADE OS PKG'
yum upgrade -y


#####安装openstack客户端相关软件

sw 'INSTALL CLIENT OF OPENSTACK'
yum install python-openstackclient -y 
               #openstack-selinux -y

yum install vim wget -y


####安装数据库

sw 'INSTALL MARIADB DBMS'
yum install mariadb mariadb-server python2-PyMySQL MySQL-python -y
cat > /etc/my.cnf.d/openstack.cnf << EOF
[mysqld]
bind-address = 0.0.0.0
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
init-connect = 'SET NAMES utf8'
EOF
sed -i "s/10.0.0.11/$controller_ip/g" /etc/my.cnf.d/openstack.cnf
sed -i "36i LimitNOFILE=65535\nLimitNPROC=65535" /usr/lib/systemd/system/mariadb.service
systemctl enable mariadb.service
systemctl start mariadb.service

mysql_secure_installation << EOF

y
password
password
y
y
y
y
EOF


#####安装消息队列

sw 'INSTALL RABBITMQ SERVER'
yum install rabbitmq-server -y
systemctl enable rabbitmq-server.service
systemctl start rabbitmq-server.service
rabbitmqctl add_user openstack password
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
rabbitmqctl set_permissions openstack -p "/" ".*" ".*" ".*"


#####安装memcached

sw 'INSTALL MEMCACHED'
yum install memcached python-memcached -y
sed -i 's/::1/10.0.0.11/g' /etc/sysconfig/memcached
sed -i "s/10.0.0.11/$controller_ip/g" /etc/sysconfig/memcached
systemctl enable memcached.service
systemctl start memcached.service


####安装etcd

sw 'INSTALL ETCD'
yum install etcd -y
cp -a /etc/etcd/etcd.conf{,.bak}
cat > /etc/etcd/etcd.conf <<EOF
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://192.168.1.81:2380"
ETCD_LISTEN_CLIENT_URLS="http://192.168.1.81:2379"
ETCD_NAME="controller"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.1.81:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.1.81:2379"
ETCD_INITIAL_CLUSTER="controller=http://192.168.1.81:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF
sed -i "s/192.168.1.81/$controller_ip/g"  /etc/etcd/etcd.conf
systemctl start etcd.service
systemctl status etcd.service



#状态查看

sw 'FIREWALLD STATUS'
systemctl status firewalld

sw 'SELINUX STATUS'
sestatus

sw 'HOSTNAME AND RESOVLE'
hostname
cat /etc/hosts

sw 'CHRONYD STATUS'
systemctl status chronyd
cat /etc/chrony.conf
chronyc sources -v

sw 'DB STATUS'
systemctl status mariadb
cat  /etc/my.cnf.d/openstack.cnf
mysql -uroot -ppassword -e 'show databases;'

sw 'RABBITMQ STATUS'
systemctl status rabbitmq-server

sw 'RABBITMQ USERS  & PERMISSIONS'
rabbitmqctl list_users
rabbitmqctl list_permissions

sw 'MEMCACHED STATUS'
systemctl status memcached
cat /etc/sysconfig/memcached

sw 'ETCD STATUS'
systemctl status etcd
cat > /etc/etcd/etcd.conf
