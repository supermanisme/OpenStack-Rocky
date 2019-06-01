#!/bin/bash
controller_ip=192.168.20.53
compute01_ip=192.168.20.54



###############################安装计算节点nova###################


yum install openstack-nova-compute python-openstackclient openstack-utils -y



openstack-config --set  /etc/nova/nova.conf DEFAULT my_ip 10.0.0.31
openstack-config --set  /etc/nova/nova.conf DEFAULT use_neutron True
openstack-config --set  /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
openstack-config --set  /etc/nova/nova.conf DEFAULT enabled_apis  osapi_compute,metadata
openstack-config --set  /etc/nova/nova.conf DEFAULT transport_url  rabbit://openstack:password@controller
openstack-config --set  /etc/nova/nova.conf api auth_strategy  keystone
openstack-config --set  /etc/nova/nova.conf keystone_authtoken auth_url http://controller:5000/v3
openstack-config --set  /etc/nova/nova.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set  /etc/nova/nova.conf keystone_authtoken auth_type password
openstack-config --set  /etc/nova/nova.conf keystone_authtoken project_domain_name Default
openstack-config --set  /etc/nova/nova.conf keystone_authtoken user_domain_name Default
openstack-config --set  /etc/nova/nova.conf keystone_authtoken project_name  service
openstack-config --set  /etc/nova/nova.conf keystone_authtoken username nova
openstack-config --set  /etc/nova/nova.conf keystone_authtoken password password
openstack-config --set  /etc/nova/nova.conf vnc enabled True
openstack-config --set  /etc/nova/nova.conf vnc server_listen 0.0.0.0
openstack-config --set  /etc/nova/nova.conf vnc server_proxyclient_address  10.0.0.31
openstack-config --set  /etc/nova/nova.conf vnc novncproxy_base_url  http://controller:6080/vnc_auto.html
openstack-config --set  /etc/nova/nova.conf glance api_servers http://controller:9292
openstack-config --set  /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp
openstack-config --set  /etc/nova/nova.conf placement region_name RegionOne
openstack-config --set  /etc/nova/nova.conf placement project_domain_name Default
openstack-config --set  /etc/nova/nova.conf placement project_name service
openstack-config --set  /etc/nova/nova.conf placement auth_type password
openstack-config --set  /etc/nova/nova.conf placement user_domain_name Default
openstack-config --set  /etc/nova/nova.conf placement auth_url http://controller:5000/v3
openstack-config --set  /etc/nova/nova.conf placement username placement
openstack-config --set  /etc/nova/nova.conf placement password password
openstack-config --set  /etc/nova/nova.conf libvirt virt_type  kvm


sed -i "s/10.0.0.31/$compute01_ip/g" /etc/nova/nova.conf
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service



#控制节点发现并检查

#su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

#openstack compute service list

#openstack catalog list

#nova-status upgrade check
