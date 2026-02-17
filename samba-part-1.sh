#! /bin/bash

sudo timedatectl set-timezone Asia/Yekaterinburg

# Установка утилит
sudo echo nameserver 8.8.8.8 >> /etc/resolv.conf && sudo apt-get update && sudo apt-get install wget dos2unix task-samba-dc -y

# Установка samba
sudo echo nameserver 192.168.1.10 >> /etc/resolv.conf
sudo echo 192.168.3.10 br-srv.au-team.irpo >> /etc/hosts
# Для HQ-SRV: echo server=/au-team.irpo/192.168.3.10 >> /etc/dnsmasq.conf
sudo rm -rf /etc/samba/smb.conf
sudo samba-tool domain provision --realm=AU-TEAM.IRPO --domain=AU-TEAM --adminpass=P@ssw0rd --dns-backend=SAMBA_INTERNAL --server-role=dc --option='dns forwarder=192.168.1.10'
sudo mv -f /var/lib/samba/private/krb5.conf /etc/krb5.conf
sudo systemctl enable --now samba.service
sudo samba-tool user add hquser1 P@ssw0rd
sudo samba-tool user add hquser2 P@ssw0rd
sudo samba-tool user add hquser3 P@ssw0rd
sudo samba-tool user add hquser4 P@ssw0rd
sudo samba-tool user add hquser5 P@ssw0rd
sudo samba-tool group add hq
sudo samba-tool group addmembers hq hquser1,hquser2,hquser3,hquser4,hquser5
