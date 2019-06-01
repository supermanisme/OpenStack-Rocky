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


##########################安装glance#####################
sw 'CREATE GLANCE DB'

mysql -u root -ppassword -e "CREATE DATABASE glance"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'password'"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'password'"

export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=password
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

sw 'create glance user'
openstack user create --domain default --password password glance

sw 'assignment admin role to glance-usr-service-project'
openstack role add --project service --user glance admin

sw 'create glance service'
openstack service create --name glance --description "OpenStack Image" image

sw 'create endpoint for glance'
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image internal http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292

sw 'install glance pkg'
yum install openstack-glance python-glance python-glanceclient -y

sw 'config glance-api file'
openstack-config --set  /etc/glance/glance-api.conf database connection  mysql+pymysql://glance:password@controller/glance
openstack-config --set  /etc/glance/glance-api.conf keystone_authtoken www_authenticate_uri http://controller:5000
openstack-config --set  /etc/glance/glance-api.conf keystone_authtoken auth_url http://controller:5000
openstack-config --set  /etc/glance/glance-api.conf keystone_authtoken memcached_servers  controller:11211
openstack-config --set  /etc/glance/glance-api.conf keystone_authtoken auth_type password
openstack-config --set  /etc/glance/glance-api.conf keystone_authtoken project_domain_name Default
openstack-config --set  /etc/glance/glance-api.conf keystone_authtoken user_domain_name Default
openstack-config --set  /etc/glance/glance-api.conf keystone_authtoken project_name service 
openstack-config --set  /etc/glance/glance-api.conf keystone_authtoken username glance
openstack-config --set  /etc/glance/glance-api.conf keystone_authtoken password password
openstack-config --set  /etc/glance/glance-api.conf paste_deploy flavor keystone
openstack-config --set  /etc/glance/glance-api.conf glance_store stores  file,http
openstack-config --set  /etc/glance/glance-api.conf glance_store default_store file
openstack-config --set  /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/

sw 'config glance-registry file'
openstack-config --set  /etc/glance/glance-registry.conf database connection mysql+pymysql://glance:password@controller/glance
openstack-config --set  /etc/glance/glance-registry.conf keystone_authtoken www_authenticate_uri http://controller:5000
openstack-config --set  /etc/glance/glance-registry.conf keystone_authtoken auth_url http://controller:5000
openstack-config --set  /etc/glance/glance-registry.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set  /etc/glance/glance-registry.conf keystone_authtoken auth_type password
openstack-config --set  /etc/glance/glance-registry.conf keystone_authtoken project_domain_name Default
openstack-config --set  /etc/glance/glance-registry.conf keystone_authtoken user_domain_name Default
openstack-config --set  /etc/glance/glance-registry.conf keystone_authtoken project_name service
openstack-config --set  /etc/glance/glance-registry.conf keystone_authtoken username glance
openstack-config --set  /etc/glance/glance-registry.conf keystone_authtoken password password
openstack-config --set  /etc/glance/glance-registry.conf paste_deploy flavor keystone

sw 'populate glance db'
su -s /bin/sh -c "glance-manage db_sync" glance

sw 'start glance services'
systemctl enable openstack-glance-api.service openstack-glance-registry.service
systemctl start openstack-glance-api.service openstack-glance-registry.service

sw 'create a cirros image'
openstack image create "cirros" \
  --file ./cirros-0.3.5-x86_64-disk.img \
  --disk-format qcow2 --container-format bare \
  --public

source admin-openrc
openstack image list

