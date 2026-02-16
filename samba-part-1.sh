#! /bin/bash

useradd sshuser -u 2026
echo -e "sshuser:P@ssw0rd" | chpasswd
timedatectl set-timezone Asia/Yekaterinburg

# Установка утилит
echo nameserver 8.8.8.8 >> /etc/resolv.conf && apt-get update && apt-get install wget dos2unix task-samba-dc -y

# Установка samba
echo nameserver 192.168.1.10 >> /etc/resolv.conf
echo 192.168.3.10 br-srv.au-team.irpo >> /etc/hosts
# Для HQ-SRV: echo server=/au-team.irpo/192.168.3.10 >> /etc/dnsmasq.conf
rm -rf /etc/samba/smb.conf
samba-tool domain provision --realm=AU-TEAM.IRPO --domain=AU-TEAM --adminpass=P@ssw0rd --dns-backend=SAMBA_INTERNAL --server-role=dc --option='dns forwarder=192.168.1.10'
mv -f /var/lib/samba/private/krb5.conf /etc/krb5.conf
systemctl enable --now samba.service
samba-tool user add hquser1 P@ssw0rd
samba-tool user add hquser2 P@ssw0rd
samba-tool user add hquser3 P@ssw0rd
samba-tool user add hquser4 P@ssw0rd
samba-tool user add hquser5 P@ssw0rd
samba-tool group add hq
samba-tool group addmembers hq hquser1,hquser2,hquser3,hquser4,hquser5
