#! /bin/bash

sudo apt-get update && sudo apt-get install -y docker-compose docker-engine
sudo systemctl enable --now docker
sudo mount -o loop /dev/sr0
sudo docker load -i /media/ALTLinux/docker/site_latest.tar
sudo docker load -i /media/ALTLinux/docker/mariadb_latest.tar


sudo cat << EOF >> launch.sh
docker compose -f site.yml up -d 
sleep 5 
docker exec -it db mysql -u root -pPassw0rd -e "
CREATE DATABASE IF NOT EXISTS testdb;

-- Создать пользователя если не существует
CREATE USER IF NOT EXISTS 'test'@'%' IDENTIFIED BY 'Passw0rd';

-- Назначить привилегии (эта команда безопасна даже если привилегии уже есть)
GRANT ALL PRIVILEGES ON testdb.* TO 'test'@'%';

-- Обновить привилегии
FLUSH PRIVILEGES;"
EOF

chmod +x /root/launch.sh
