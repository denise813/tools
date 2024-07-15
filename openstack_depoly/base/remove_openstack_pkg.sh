set -x

dis_ver='queens'
os_name='contos7'

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


if [ ${dis_ver} == "queens" ]; then
    yum remove centos-release-openstack-queens -y
    #cp config/CentOS-OpenStack-queens.repo /etc/yum.repos.d/CentOS-OpenStack-queens.repo
    #yum clean all
    #yum makecache
fi

#yum upgrade -y
if [ ${os_name} == "centos7" ]; then
    yum remove python-openstackclient python2-qpid-proton-0.22.0-1.el7.x86_64 qpid-proton-c-0.22.0-1.el7.x86_64 -y
elif [ ${os_name} == "centos8" ]; then
    yum remove python3-openstackclient -y
else
    exit 22
fi

yum remove openstack-selinux -y

echo "remove finish openstack pkg"