set -x
#############################################
#
yum install rabbitmq-server -y

systemctl enable rabbitmq-server.service
systemctl start rabbitmq-server.service
rabbitmqctl add_user openstack RABBIT_PASS
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

rabbitmqctl list_users
echo "install finish rabbitmq"
