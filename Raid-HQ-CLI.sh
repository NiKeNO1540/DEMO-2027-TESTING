#! /bin/bash

apt-get update && apt-get install nfs-clients -y
mkdir -p /mnt/nfs
cat << EOF >> /etc/fstab
192.168.1.10:/raid/nfs  /mnt/nfs  nfs  intr,soft,_netdev,x-systemd.automount  0  0
EOF
mount -a
mount -v
touch /mnt/nfs/test
