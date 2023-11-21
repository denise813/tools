
mkdir -p origin
systemctl stop openvswitch
systemctl disable openvswitch
yum remove python-openstackclient python2-qpid-proton qpid-proton-c -y
yum remove openstack-nova-compute -y
rm -rf /etc/nova
rm -rf /var/log/nova
rm -rf /var/lib/nova

systemctl stop neutron-linuxbridge-agent.service
yum remove openstack-neutron-linuxbridge openstack-neutron-openvswitch ebtables ipset -y
rm -rf /etc/neutron
rm -rf /var/log/neutron
rm -rf /var/lib/neutron

#systemctl stop libvirtd.service
#systemctl disable libvirtd.service

#yum -y remove qemu-kvm\* python-virtinst\* libvirt\* libvirt-python\* virt-manager\* libguestfs-tools\* bridge-utils\* virt-install\*
#rm -rf /var/lib/libvirt
