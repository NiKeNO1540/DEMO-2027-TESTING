#! /bin/bash

useradd sshuser -u 2026
echo -e "sshuser:P@ssw0rd" | chpasswd
timedatectl set-timezone Asia/Yekaterinburg

echo nameserver 8.8.8.8 >> /etc/resolv.conf

# Обновление, установка утилиты dnsmasq

apt-get update
apt-get install dnsmasq -y
systemctl enable --now dnsmasq

cat << EOF >> /etc/dnsmasq.conf
no-resolv
domain=au-team.irpo
server=8.8.8.8
interface=*
address=/hq-rtr.au-team.irpo/192.168.1.1
server=/au-team.irpo/192.168.3.10
ptr-record=1.1.168.192.in-addr.arpa,hq-rtr.au-team.irpo
address=/web.au-team.irpo/172.16.2.1
address=/docker.au-team.irpo/172.16.1.1
address=/br-rtr.au-team.irpo/192.168.3.1
address=/hq-srv.au-team.irpo/192.168.1.10
ptr-record=10.1.168.192.in-addr.arpa,hq-srv.au-team.irpo
address=/hq-cli.au-team.irpo/192.168.2.10
ptr-record=10.2.168.192.in-addr.arpa,hq-cli.au-team.irpo
address=/br-srv.au-team.irpo/192.168.3.10
EOF

echo "192.168.1.1 hq-rtr.au-team.irpo" >> /etc/hosts

systemctl restart dnsmasq
