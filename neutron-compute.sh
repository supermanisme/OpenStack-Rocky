#!/bin/bash

#####显示边框

function sw(){
echo "#############################################"
echo "$1"
echo "#############################################"
echo ""
echo ""
sleep 10s
}

#系统变量
controller_ip=192.168.20.53
compute01_ip=192.168.20.54


######################安装计算节点neutron####################

sw 'install neutron pkg in compute node'
yum install openstack-neutron-linuxbridge ebtables ipset -y

sw 'config neutron.conf file'
openstack-config --set /etc/neutron/neutron.conf DEFAULT transport_url  rabbit://openstack:password@controller
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri  http://controller:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password password
openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp


sw 'config neutron linnxbridge config file'
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings  provider:eth1
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan true
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip 192.168.20.54
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population true
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group true
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

sw 'config nova in neutron file'
openstack-config --set /etc/nova/nova.conf neutron url http://controller:9696
openstack-config --set /etc/nova/nova.conf neutron auth_url http://controller:5000
openstack-config --set /etc/nova/nova.conf neutron auth_type password
openstack-config --set /etc/nova/nova.conf neutron project_domain_name default
openstack-config --set /etc/nova/nova.conf neutron user_domain_name default
openstack-config --set /etc/nova/nova.conf neutron region_name RegionOne
openstack-config --set /etc/nova/nova.conf neutron project_name service
openstack-config --set /etc/nova/nova.conf neutron username neutron
openstack-config --set /etc/nova/nova.conf neutron password password


sed -i "s/10.0.0.31/$compute01_ip/g" /etc/neutron/plugins/ml2/linuxbridge_agent.ini

sw 'start nova & neutron services'
systemctl restart openstack-nova-compute.service


systemctl enable neutron-linuxbridge-agent.service
systemctl start neutron-linuxbridge-agent.service
