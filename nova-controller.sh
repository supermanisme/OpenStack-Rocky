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




#####################安装控制节点nova#########################
sw 'create nova* database'
mysql -u root -ppassword -e "CREATE DATABASE nova_api"
mysql -u root -ppassword -e "CREATE DATABASE nova"
mysql -u root -ppassword -e "CREATE DATABASE nova_cell0"
mysql -u root -ppassword -e "CREATE DATABASE placement"

mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'password'"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'password'"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'password'"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'password'"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY 'password'"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'password'"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY 'password'"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY 'password'"

export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=password
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

sw 'create nova user'
openstack user create --domain default --password password nova

sw 'ssignment admin to nova user'
openstack role add --project service --user nova admin

sw 'create compute service'
openstack service create --name nova --description "OpenStack Compute" compute

sw 'create endpoint for nova'
openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1

sw 'create placement user'
openstack user create --domain default --password password placement

sw 'assign admin role to placement'
openstack role add --project service --user placement admin

sw 'create placement srvice'
openstack service create --name placement --description "Placement API" placement

sw 'create endpoing for placement'
openstack endpoint create --region RegionOne placement public http://controller:8778
openstack endpoint create --region RegionOne placement internal http://controller:8778
openstack endpoint create --region RegionOne placement admin http://controller:8778

sw 'install nova pgk'
yum install openstack-nova-api openstack-nova-conductor \
  openstack-nova-console openstack-nova-novncproxy \
  openstack-nova-scheduler openstack-nova-placement-api -y

sw 'config nova.conf'
openstack-config --set  /etc/nova/nova.conf DEFAULT my_ip 10.0.0.11
openstack-config --set  /etc/nova/nova.conf DEFAULT use_neutron  true 
openstack-config --set  /etc/nova/nova.conf DEFAULT firewall_driver  nova.virt.firewall.NoopFirewallDriver
openstack-config --set  /etc/nova/nova.conf DEFAULT transport_url  rabbit://openstack:password@controller
openstack-config --set  /etc/nova/nova.conf api_database connection  mysql+pymysql://nova:password@controller/nova_api
openstack-config --set  /etc/nova/nova.conf database connection  mysql+pymysql://nova:password@controller/nova
openstack-config --set  /etc/nova/nova.conf placement_database connection  mysql+pymysql://placement:password@controller/placement
openstack-config --set  /etc/nova/nova.conf api auth_strategy  keystone 
openstack-config --set  /etc/nova/nova.conf keystone_authtoken auth_url  http://controller:5000/v3
openstack-config --set  /etc/nova/nova.conf keystone_authtoken memcached_servers  controller:11211
openstack-config --set  /etc/nova/nova.conf keystone_authtoken auth_type  password
openstack-config --set  /etc/nova/nova.conf keystone_authtoken project_domain_name  Default 
openstack-config --set  /etc/nova/nova.conf keystone_authtoken user_domain_name  Default
openstack-config --set  /etc/nova/nova.conf keystone_authtoken project_name  service 
openstack-config --set  /etc/nova/nova.conf keystone_authtoken username  nova 
openstack-config --set  /etc/nova/nova.conf keystone_authtoken password  password
openstack-config --set  /etc/nova/nova.conf vnc enabled true
openstack-config --set  /etc/nova/nova.conf vnc server_listen 10.0.0.11
openstack-config --set  /etc/nova/nova.conf vnc server_proxyclient_address 10.0.0.11
openstack-config --set  /etc/nova/nova.conf glance api_servers  http://controller:9292
openstack-config --set  /etc/nova/nova.conf oslo_concurrency lock_path  /var/lib/nova/tmp 
openstack-config --set  /etc/nova/nova.conf placement region_name RegionOne
openstack-config --set  /etc/nova/nova.conf placement project_domain_name Default
openstack-config --set  /etc/nova/nova.conf placement project_name service
openstack-config --set  /etc/nova/nova.conf placement auth_type password
openstack-config --set  /etc/nova/nova.conf placement user_domain_name Default
openstack-config --set  /etc/nova/nova.conf placement auth_url http://controller:5000/v3
openstack-config --set  /etc/nova/nova.conf placement username placement
openstack-config --set  /etc/nova/nova.conf placement password password
openstack-config --set  /etc/nova/nova.conf scheduler discover_hosts_in_cells_interval 300


sed -i "s/10.0.0.11/$controller_ip/g" /etc/nova/nova.conf
cat >> /etc/httpd/conf.d/00-nova-placement-api.conf << EOF

<Directory /usr/bin>
   <IfVersion >= 2.4>
      Require all granted
   </IfVersion>
   <IfVersion < 2.4>
      Order allow,deny
      Allow from all
   </IfVersion>
</Directory>
EOF
systemctl restart httpd

sw 'init nvoa-api & placement DB'
su -s /bin/sh -c "nova-manage api_db sync" nova

sw 'registry cell0 DB'
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova

sw 'create cell1'
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova

sw 'init nova DB'
su -s /bin/sh -c "nova-manage db sync" nova

sw 'init nova DB'
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova

sw 'start nova services'
systemctl enable openstack-nova-api.service \
  openstack-nova-consoleauth.service openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service
systemctl start openstack-nova-api.service \
  openstack-nova-consoleauth.service openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service


systemctl status openstack-nova-api.service \
  openstack-nova-consoleauth.service openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service

