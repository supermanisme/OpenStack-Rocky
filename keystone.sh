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


##############################################
#                                            #
#          控制节点操作                      #   
#                                            #  
##############################################


##########安装keystone##############

###########配置数据库########################

sw 'ADD KEYSTONE DATABASE'
mysql -u root -ppassword -e "CREATE DATABASE keystone"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'password'"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'password'"

sw 'INSTALL KEYSTONE PKG'
yum install openstack-keystone httpd mod_wsgi python-keystoneclient openstack-utils -y

sw 'CONFIG KEYSTONE.CONF'
openstack-config --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:password@controller/keystone
openstack-config --set /etc/keystone/keystone.conf token provider fernet

sw 'POPULATE KEYTONE DATABASE'
su -s /bin/sh -c "keystone-manage db_sync" keystone
sleep 10s
mysql -ukeystone -ppassword -e "use keystone;show tables;"

sw 'init fernet token'
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
sleep 10s

keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
sleep 10s

sw 'CONFIG HTTPD'
sed -i "s/#ServerName www.example.com/ServerName controller/g" /etc/httpd/conf/httpd.conf
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/

systemctl enable httpd.service
systemctl restart httpd.service

sw 'init start keystone service'
sleep 10s
keystone-manage bootstrap --bootstrap-password password \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne


export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=password
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

sw 'create domain example'
openstack domain create --description "An Example Domain" example

sw 'create project service'
openstack project create --domain default --description "Service Project" service

sw 'create project myproject'
openstack project create --domain default --description "Demo Project" myproject

sw 'create user myuser'
openstack user create --domain default  --password=password myuser

sw 'create role myrole'
openstack role create myrole

sw 'assign role to myuser-myproject'
openstack role add --project myproject --user myuser myrole

#验证
#unset OS_AUTH_URL OS_PASSWORD
#openstack --os-auth-url http://controller:5000/v3 \
#  --os-project-domain-name Default --os-user-domain-name Default \
#  --os-project-name admin --os-username admin token issue

#openstack --os-auth-url http://controller:5000/v3 \
#  --os-project-domain-name Default --os-user-domain-name Default \
#  --os-project-name myproject --os-username myuser token issue
















