#! /bin/bash

sudo apt-get update
sudo apt-get install nfs-clients -y

sudo mkdir -p /mnt/nfs

sudo cat << EOF >> /etc/fstab
192.168.1.10:/raid5/nfs  /mnt/nfs    nfs   intr,soft,_netdev,x-systemd.automount    0    0
EOF
sudo mount -a
sudo mount -v

sudo touch /mnt/nfs/test
