# Установка необходимых пакетов
sudo apt-get update
sudo apt-get install lamp-server -y

# Запуск и включение служб
sudo systemctl enable --now httpd2 mariadb

# Монтирование образа
sudo mkdir -p /mnt/additional
sudo mount /dev/sr0 /mnt/additional -o ro

# Создание рабочей директории
sudo mkdir -p /tmp/web_setup
sudo cp -r /mnt/additional/web/* /tmp/web_setup/

# Настройка MySQL/MariaDB
sudo mysql -e "CREATE DATABASE webdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER 'webc'@'localhost' IDENTIFIED BY 'P@ssw0rd';"
sudo mysql -e "GRANT ALL PRIVILEGES ON webdb.* TO 'webc'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Импорт базы данных (обработка кодировки)
sudo cd /tmp/web_setup
# Проверяем кодировку файла
sudo file -i dump.sql

# Если файл в UTF-16 или другой кодировке, конвертируем
if sudo file -i dump.sql | grep -q "utf-16"; then
    sudo iconv -f UTF-16 -t UTF-8 dump.sql > dump_utf8.sql
    sudo mysql -u root webdb < dump_utf8.sql
else
    sudo mysql -u root webdb < dump.sql
fi

# Копирование файлов веб-приложения
sudo cp index.php /var/www/html/
sudo cp -r logo.png /var/www/html/

# Настройка прав доступа
sudo chown -R apache2:apache2 /var/www/html
sudo chmod -R 755 /var/www/html

# Настройка подключения к БД в index.php
# Исправляем учетные данные для подключения
sudo sed -i "s/\$servername = .*;/\$servername = 'localhost';/" /var/www/html/index.php
sudo sed -i "s/\$dbname = .*;/\$dbname = 'webdb';/" /var/www/html/index.php
sudo sed -i "s/\$password = .*;/\$password = 'P@ssw0rd';/" /var/www/html/index.php
sudo sed -i "s/\$username = .*;/\$username = 'webc';/" /var/www/html/index.php

sudo sed -i 's/\tDirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm/\tDirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/' /etc/httpd2/conf/mods-enabled/dir.conf
sudo rm -rf /var/www/html/index.html

# Перезагрузка Apache
sudo systemctl restart httpd2

# Проверка работоспособности
sudo curl -I http://localhost/
