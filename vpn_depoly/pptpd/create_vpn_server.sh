net_dev=eth0
# clean
yum -y remove pptpd
rm -rf /etc/pptpd.conf
rm -rf /etc/ppp/*

# ppp安装ppp
yum -y install pptpd
mkdir -p ./config
mkdir -p ./origin

vpn_ip=$(ip addr show ${net_dev}|grep inet|grep -v inet6|awk '{split($2, ip, "/"); print ip[1]}')
if [ ! -e origin/pptpd.conf.origin ]; then
    cp /etc/pptpd.conf ./origin/pptpd.conf.origin
fi
file_buff=$(cat ./origin/pptpd.conf.origin)
cat<< EOF >> /etc/pptpd.conf
${file_buff}
localip ${vpn_ip}
remoteip 0.0.0.0
EOF

if [ ! -e origin/options.pptpd.origin ]; then
    cp /etc/ppp/options.pptpd ./origin/options.conf.origin
fi
file_buff=$(cat ./origin/options.conf.origin)
cat << EOF >> /etc/ppp/options.pptpd
${file_buff}
ms-dns 180.76.76.76
#ms-dns 180.76.76.76
EOF

if [ ! -e origin/chap-secrets.origin ]; then
    cp /etc/ppp/chap-secrets ./origin/chap-secrets.origin
fi
file_buff=$(cat ./origin/chap-secrets.origin)
cat << EOF >> /etc/ppp/chap-secrets
${file_buff}
deise813	pptpd	hy123456	*
EOF

if [ ! -e origin/sysctl.conf ]; then
    cp /etc/sysctl.conf ./origin/sysctl.conf.origin
fi
file_buff=$(cat ./origin/sysctl.conf.origin)
cat << EOF >> /etc/sysctl.conf
${file_buff}
net.ipv4.ip_forward = 1
EOF

sysctl -p

systemctl restart pptpd

systemctl enable pptpd

iptables -nL

#route
# ss -nutlp |grep pptpd
