#systemctl restart chronyd.service
#systemctl restart memcached.service
#systemctl restart rabbitmq-server.service
#systemctl restart httpd.service
systemctl restart openstack-glance-api.service
systemctl restart openstack-glance-registry.service

systemctl restart openstack-nova-api.service
systemctl restart openstack-nova-consoleauth.service
systemctl restart openstack-nova-scheduler.service
systemctl restart openstack-nova-conductor.service
systemctl restart openstack-nova-novncproxy.service

systemctl restart neutron-server.service
systemctl restart neutron-linuxbridge-agent.service
systemctl restart neutron-dhcp-agent.service
systemctl restart neutron-metadata-agent.service

systemctl restart openstack-cinder-api.service
systemctl restart openstack-cinder-scheduler.service

systemctl restart httpd.service
systemctl restart memcached.service
