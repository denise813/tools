set -x

controller='192.169.100.150'
os_name="centos7"

while [ -n "$1" ]
do
	case "$1" in
		--controller)
			array[${#array[*]}]=$1;array[${#array[*]}]=$2;controller=$2;shift;shift;continue
			;;
		--os)
			array[${#array[*]}]=$1;array[${#array[*]}]=$2;os_name=$2;shift;shift;continue
			;;
		*)
			array[${#array[*]}]=$1;shift;continue
			;;
	esac
done

################################################
#
#----------------------------------------------

if [ ${os_name} == "centos7" ]; then
    yum install memcached python-memcached -y
elif [ ${os_name} == "cnetos8" ]; then
    yum install memcached python3-memcached -y
else
   exit 22
fi

if [ -e 'origin/memcached.temple' ]; then
    cp /etc/sysconfig/memcached origin/memcached.temple
fi

cat <<EOF > /etc/sysconfig/memcached
PORT="11211"
USER="memcached"
MAXCONN="1024"
CACHESIZE="64"
OPTIONS="-l 0.0.0.0"
EOF
systemctl enable memcached.service
systemctl start memcached.service

echo "install finish memcached on ${controller}"
