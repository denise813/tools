origin_file=$1
template_file=/tmp/ceph.conf
rm -rf ${template_file}

while [ $# -gt 0 ];
do
   case $1 in
	-public) public_interface=$2
		shift
		;;
	-cluster) cluster_interface=$2
		shift
		;;
	-mon) mon=$2
		shift
		;;
	-osds) osds=$2
		shift
		;;
   esac
   shift
done

public_addr=$(/sbin/ifconfig ${public_interface} | awk '/inet/ {print $2}' | cut -f2 -d ":" |awk 'NR==1 {print $1}')
cluster_addr=$(/sbin/ifconfig ${cluster_interface} | awk '/inet/ {print $2}' | cut -f2 -d ":" |awk 'NR==1 {print $1}')

sed -i '/mon initial members = /a ${node_name}' ${origin_file} > ${template_file}
sed -i '/mon host = /a ${public_addr}' ${origin_file} > ${template_file}

