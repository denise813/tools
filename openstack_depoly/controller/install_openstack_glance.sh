set -x

controller="192.168.100.150"

while [ -n "$1" ]
do
    case "$1" in
        --controller)
            array[${#array[*]}]=$1;array[${#array[*]}]=$2;controller=$2;shift;shift;continue
            ;;
        *)
            array[${#array[*]}]=$1;shift;continue
            ;;
    esac
done

#############################################
local_host_name=$(hostname)

mysql -h ${controller} -u root -e "DROP DATABASE glance;"
mysql -h ${controller} -u root -e "CREATE DATABASE glance;"

mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'GLANCE_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'${local_host_name}' IDENTIFIED BY 'GLANCE_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'${controller}' IDENTIFIED BY 'GLANCE_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'GLANCE_DBPASS';"

openstack user create --domain default --password  GLANCE_PASS glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image
openstack endpoint create --region RegionOne image public http://${controller}:9292
openstack endpoint create --region RegionOne image internal http://${controller}:9292
openstack endpoint create --region RegionOne image admin http://${controller}:9292

yum install openstack-glance python2-qpid-proton-0.22.0-1.el7.x86_64 qpid-proton-c-0.22.0-1.el7.x86_64 -y

mkdir -p origin

if [ -e origin/glance-api.conf.origin ];then
    cp /etc/glance/glance-api.conf glance-api.conf.origin
fi

if [ -e origin/glance-registry.conf.origin ];then
    cp /etc/galnce/glance-registry.conf glance-registry.conf.origin
fi

buffer=$(sed "s/<controller>/${controller}/g" config/glance-api.conf)
cat <<EOF > /etc/glance/glance-api.conf
${buffer}

EOF

buffer=$(sed "s/<controller>/${controller}/g" config/glance-registry.conf)
cat <<EOF > /etc/glance/glance-registry.conf
${buffer}

EOF

su -s /bin/sh -c "glance-manage db_sync" glance

systemctl enable openstack-glance-api.service
systemctl enable openstack-glance-registry.service
systemctl start openstack-glance-api.service
systemctl start openstack-glance-registry.service

source ./openrc

echo "install finish glance on ${controller}"
