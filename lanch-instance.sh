openstack network create  --share --external \
  --provider-physical-network provider \
  --provider-network-type flat provider


openstack subnet create --network provider \
  --allocation-pool start=203.0.113.101,end=203.0.113.250 \
  --dns-nameserver 8.8.4.4 --gateway 203.0.113.1 \
  --subnet-range 203.0.113.0/24 provider


openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano

 openstack security group rule create --proto icmp default


openstack security group rule create --proto tcp --dst-port 22 default


openstack server create --flavor m1.nano --image cirros \
  --nic net-id=PROVIDER_NET_ID --security-group default \
  --key-name mykey provider-instance

