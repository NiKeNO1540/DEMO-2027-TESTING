#! /bin/bash

useradd sshuser -u 2026
echo -e "sshuser:P@ssw0rd" | chpasswd
timedatectl set-timezone Asia/Yekaterinburg

apt-get install sudo libsss_sudo -y
control sudo public
sed -i '19 a\
sudo_provider = ad' /etc/sssd/sssd.conf
sed -i 's/services = nss, pam/services = nss, pam, sudo/' /etc/sssd/sssd.conf
sed -i '28 a\
sudoers: files sss' /etc/nsswitch.conf
