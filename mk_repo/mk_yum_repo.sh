
data_dir="/var/www/html/yum/contos7"
yum_server_ip="192.168.110.220"
repo_name="ys_openstack"
repo_item="ys_openstack"
repo_item_name="ys_openstack"
rm -rf ${data_dir}
mkdir ${data_dir}
yum -y install createrepo
createrepo -pdo ${data_dir} ${data_dir}

cp ./sources/* ${data_dir}/
yum install -y httpd
systemctl start httpd.service
createrepo --update ${data_dir}

cat <<EOF > ./${repo_name}.repo
[${repo_item}]
name=${repo_item_name}
baseurl=http://${yum_server_ip}/yum//centos7
enable=1
gpgcheck=0
EOF

