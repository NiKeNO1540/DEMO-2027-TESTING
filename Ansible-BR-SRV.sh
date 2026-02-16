#! /bin/bash

apt-get update && apt-get install ansible -y

cat << EOF >> /etc/ansible/hosts
VMs:
  hosts:
    HQ-SRV:
      ansible_host: 172.16.1.4
      ansible_user: sshuser
      ansible_port: 2026
    HQ-CLI:
      ansible_host: 172.16.1.4
      ansible_user: sshuser
      ansible_port: 2222
    HQ-RTR:
      ansible_host: 192.168.1.1
      ansible_user: net_admin
      ansible_password: P@ssw0rd
      ansible_connection: network_cli
      ansible_network_os: ios
    BR-RTR:
      ansible_host: 192.168.3.1
      ansible_user: net_admin
      ansible_password: P@ssw0rd
      ansible_connection: network_cli
      ansible_network_os: ios
EOF

sed -i '10 a\
ansible_python_interpreter=/usr/bin/python3\
interpreter_python=auto_silent\
ansible_host_key_checking=false' /etc/ansible/ansible.cfg

ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa -q
apt-get install sshpass -y
grep -q "172.16.1.4:2026" ~/.ssh/known_hosts 2>/dev/null || ssh-keyscan -p 2026 172.16.1.4 >> ~/.ssh/known_hosts
grep -q "172.16.1.4:2222" ~/.ssh/known_hosts 2>/dev/null || ssh-keyscan -p 2222 172.16.1.4 >> ~/.ssh/known_hosts
sshpass -p "P@ssw0rd" ssh-copy-id -p 2026 sshuser@172.16.1.4
sshpass -p "P@ssw0rd" ssh-copy-id -p 2222 sshuser@172.16.1.4

ansible all -m ping
