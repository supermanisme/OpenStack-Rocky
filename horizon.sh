#!/bin/bash
yum install openstack-dashboard -y




echo 'WSGIApplicationGroup %{GLOBAL}' >> /etc/httpd/conf.d/openstack-dashboard.conf
systemctl restart httpd.service memcached.service

