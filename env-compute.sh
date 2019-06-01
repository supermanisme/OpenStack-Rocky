#!/bin/bash

#显示边框
function sw(){
echo "#############################################"
echo "$1"
echo "#############################################"
echo ""
echo ""
sleep 10s
}

#网络参数变量
export controller_ip=192.168.20.53
export compute01_ip=192.168.20.54

###############################################
##                                            #
##          计算节点操作环境准备              #   
##                                            #  
###############################################

#网络配置和kvm虚拟化开启查询


##############配置安装源#######################

sw 'CONFIGE YUM REPO'
yum install centos-release-openstack-rocky -y

##安装工具

yum install net-tools vim -y


##############关闭防火墙和seliux###############

sw 'STOP & DISABLE FIREWALLD AND SELINUX'
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config


#################主机名及解析##################

sw 'SHOTNAME ADN RESOVLE'
hostnamectl set-hostname compute01
export HOSTNAME=compute01
echo 10.0.0.11 controller >> /etc/hosts
echo 10.0.0.12 compute01 >> /etc/hosts
sed -i "s/10.0.0.11/$controller_ip/g" /etc/hosts
sed -i "s/10.0.0.12/$compute01_ip/g" /etc/hosts


#########时间同步，控制节点作为时间同步服务器###

sw 'NTP SERVER '
yum install chrony -y
sed -i 's/server 0.centos.pool.ntp.org iburst/server controller iburst/g' /etc/chrony.conf
sed -i 's/server 1.centos.pool.ntp.org iburst/#server 1.centos.pool.ntp.org iburs/g' /etc/chrony.conf
sed -i 's/server 2.centos.pool.ntp.org iburst/#server 1.centos.pool.ntp.org iburs/g' /etc/chrony.conf
sed -i 's/server 3.centos.pool.ntp.org iburst/#server 1.centos.pool.ntp.org iburs/g' /etc/chrony.conf
systemctl restart chronyd
systemctl enable chronyd


#########升级并安装openstack客户端################

sw 'UPGRADE OS'
yum upgrade -y
yum install python-openstackclient -y
#openstack-selinux -y

