#! /bin/bash

sudo mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/sd[b-c]
sudo mdadm --detail -scan --verbose > /etc/mdadm.conf
sudo apt-get update && sudo apt-get install fdisk -y
sudo fdisk /dev/md0 << EOF
n
p
1
2048
4186111
w
EOF

sudo mkfs.ext4 /dev/md0p1
sudo cat << EOF >> /etc/fstab
/dev/md0p1  /raid  ext4  defaults  0  0
EOF

sudo mkdir /raid
sudo mount -a

sudo apt-get install nfs-server -y
sudo mkdir /raid/nfs
sudo chown 99:99 /raid/nfs
sudo chmod 777 /raid/nfs

sudo cat << EOF >> /etc/exports
/raid/nfs  192.168.2.0/28(rw,sync,no_subtree_check)
EOF
sudo exportfs -a
sudo exportfs -v
sudo systemctl enable nfs
sudo systemctl restart nfs
