#! /bin/bash

mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/sd[b-c]

mdadm  --detail -scan --verbose > /etc/mdadm.conf

apt-get update && apt-get install fdisk -y

fdisk /dev/md0

mkfs.ext4 /dev/md0p1

cat << EOF >> /etc/fstab
/dev/md0p1    /raid5  ext4    defaults     0     0
EOF

mkdir /raid
mount -a
apt-get install nfs-server -y
mkdir /raid/nfs
chown 99:99 /raid/nfs
chmod 777 /raid/nfs
echo "/raid/nfs 192.168.2.0/28(rw,sync,no_subtree_check)
exportfs -a
exportfs -v
systemctl enable --now nfs
