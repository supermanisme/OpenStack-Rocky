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
##          控制节点操作                      #   
##                                            #  
###############################################



###################安装控制节点neutron######################

mysql -u root -ppassword -e "CREATE DATABASE neutron"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'password'"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'password'"

export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=password
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

openstack user create --domain default --password password neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron \
  --description "OpenStack Networking" network
openstack endpoint create --region RegionOne \
  network public http://controller:9696
openstack endpoint create --region RegionOne \
  network internal http://controller:9696
openstack endpoint create --region RegionOne \
  network admin http://controller:9696

yum install openstack-neutron openstack-neutron-ml2 \
  openstack-neutron-linuxbridge ebtables -y

openstack-config --set  /etc/neutron/neutron.conf database connection  mysql+pymysql://neutron:password@controller/neutron
openstack-config --set  /etc/neutron/neutron.conf DEFAULT core_plugin  ml2
openstack-config --set  /etc/neutron/neutron.conf DEFAULT service_plugins router
openstack-config --set  /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips true
openstack-config --set  /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:password@controller
openstack-config --set  /etc/neutron/neutron.conf DEFAULT auth_strategy  keystone
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri  http://controller:5000
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken auth_url  http://controller:5000
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken memcached_servers  controller:11211
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken auth_type  password
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken user_domain_name  default
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken project_name  service
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken username  neutron
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken password  password
openstack-config --set  /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes  True
openstack-config --set  /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes  True
openstack-config --set  /etc/neutron/neutron.conf nova auth_url  http://controller:5000
openstack-config --set  /etc/neutron/neutron.conf nova auth_type  password
openstack-config --set  /etc/neutron/neutron.conf nova project_domain_name  default
openstack-config --set  /etc/neutron/neutron.conf nova user_domain_name  default
openstack-config --set  /etc/neutron/neutron.conf nova region_name  RegionOne
openstack-config --set  /etc/neutron/neutron.conf nova project_name  service
openstack-config --set  /etc/neutron/neutron.conf nova username  nova
openstack-config --set  /etc/neutron/neutron.conf nova password  password
openstack-config --set  /etc/neutron/neutron.conf oslo_concurrency lock_path  /var/lib/neutron/tmp


openstack-config --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers  flat,vlan,vxlan
openstack-config --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
openstack-config --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers  linuxbridge,l2population
openstack-config --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers  port_security
openstack-config --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks  provider
openstack-config --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000
openstack-config --set  /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset  True


openstack-config --set   /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings  provider:eth1
openstack-config --set   /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan  enable_vxlan  true
openstack-config --set   /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan  local_ip  192.168.20.53
openstack-config --set   /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan  l2_population true
openstack-config --set   /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup  enable_security_group  True
openstack-config --set   /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup  firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver



openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver linuxbridge
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata true


openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver linuxbridge


openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host controller
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret password

openstack-config --set  /etc/nova/nova.conf  neutron url http://controller:9696
openstack-config --set  /etc/nova/nova.conf  neutron auth_url http://controller:5000
openstack-config --set  /etc/nova/nova.conf  neutron auth_type password
openstack-config --set  /etc/nova/nova.conf  neutron project_domain_name default
openstack-config --set  /etc/nova/nova.conf  neutron user_domain_name default
openstack-config --set  /etc/nova/nova.conf  neutron region_name RegionOne
openstack-config --set  /etc/nova/nova.conf  neutron project_name service
openstack-config --set  /etc/nova/nova.conf  neutron username neutron
openstack-config --set  /etc/nova/nova.conf  neutron password password
openstack-config --set  /etc/nova/nova.conf  neutron service_metadata_proxy true
openstack-config --set  /etc/nova/nova.conf  neutron metadata_proxy_shared_secret password


ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

systemctl restart openstack-nova-api.service

systemctl enable neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service neutron-l3-agent.service

systemctl start neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service neutron-l3-agent.service
