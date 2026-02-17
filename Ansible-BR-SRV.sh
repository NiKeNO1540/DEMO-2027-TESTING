#! /bin/bash

sudo apt-get update && sudo apt-get install ansible -y

sudo cat << EOF >> /etc/ansible/hosts
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

sudo sed -i '10 a\
ansible_python_interpreter=/usr/bin/python3\
interpreter_python=auto_silent\
ansible_host_key_checking=false' /etc/ansible/ansible.cfg

sudo ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa -q
sudo apt-get install sshpass -y
sudo grep -q "172.16.1.10:2026" ~/.ssh/known_hosts 2>/dev/null || sudo ssh-keyscan -p 2026 172.16.1.4 >> ~/.ssh/known_hosts
sudo grep -q "172.16.1.10:2222" ~/.ssh/known_hosts 2>/dev/null || sudo ssh-keyscan -p 2222 172.16.1.4 >> ~/.ssh/known_hosts
sudo sshpass -p "P@ssw0rd" ssh-copy-id -p 2026 sshuser@172.16.1.4
sudo sshpass -p "P@ssw0rd" ssh-copy-id -p 2222 sshuser@172.16.1.4

sudo ansible all -m ping
