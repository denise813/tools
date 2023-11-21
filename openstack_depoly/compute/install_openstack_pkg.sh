set -x

dis_ver=''
os_name=''

while [ -n "$1" ]
    do
        case "$1" in
            --dis)
                array[${#array[*]}]=$1;array[${#array[*]}]=$2;dis_ver=$2;shift;shift;continue
                ;;
            --os)
                array[${#array[*]}]=$1;array[${#array[*]}]=$2;os_name=$2;shift;shift;continue
                ;;
            *)
                array[${#array[*]}]=$1;shift;continue
                ;;
        esac
    done

systemctl stop firewalld
systemctl disable firewalld
systemctl stop iptables
systemctl disable iptables
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
systemctl stop NetworkManager
#systemctl disable NetworkManager


if [ ${dis_ver} == "queens" ]; then
    yum install centos-release-openstack-queens -y
    cp config/CentOS-OpenStack-queens.repo /etc/yum.repos.d/CentOS-OpenStack-queens.repo
    #yum clean all
    #yum makecache
fi

#yum upgrade -y
if [ ${os_name} == "centos7" ]; then
    yum install python-openstackclient python2-qpid-proton-0.22.0-1.el7.x86_64 qpid-proton-c-0.22.0-1.el7.x86_64 -y
elif [ ${os_name} == "centos8" ]; then
    yum install python3-openstackclient -y
else
    exit 22
fi

yum install openstack-selinux -y

echo "install finish openstack pkg"
