#!/bin/bash

# Функция для логирования
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

echo "Начало выполнения скрипта настройки ISP"
log_message "Старт скрипта настройки ISP"

echo "Настройка ISP"
log_message "Создание директорий для сетевых интерфейсов"
mkdir -p /etc/net/ifaces/ens21
mkdir -p /etc/net/ifaces/ens22
log_message "Директории созданы: /etc/net/ifaces/ens21, /etc/net/ifaces/ens22"

log_message "Создание конфигурационных файлов для сетевых интерфейсов"
echo -e "BOOTPROTO=static\nTYPE=eth\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens21/options
echo -e "BOOTPROTO=static\nTYPE=eth\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens22/options
log_message "Конфигурационные файлы options созданы"

log_message "Назначение IP-адресов интерфейсам"
echo "172.16.1.1/28" > /etc/net/ifaces/ens21/ipv4address
echo "172.16.2.1/28" > /etc/net/ifaces/ens22/ipv4address
log_message "IP-адреса назначены: ens21=172.16.1.1/28, ens22=172.16.2.1/28"

log_message "Перезапуск сетевой службы"
systemctl restart network
log_message "Сетевая служба перезапущена"

echo "Настройка IPTABLES"
log_message "Установка iptables"
apt-get install iptables -y
if [ $? -eq 0 ]; then
    log_message "IPTABLES успешно установлен"
else
    log_message "Ошибка установки IPTABLES"
fi

log_message "Настройка правил NAT"
iptables -t nat -A POSTROUTING -o ens20 -s 172.16.1.0/28 -j MASQUERADE
iptables -t nat -A POSTROUTING -o ens20 -s 172.16.2.0/28 -j MASQUERADE
log_message "Правила NAT добавлены"

log_message "Сохранение правил iptables"
iptables-save > /etc/sysconfig/iptables
log_message "Правила сохранены в /etc/sysconfig/iptables"

log_message "Включение автозагрузки iptables"
systemctl enable --now iptables
if [ $? -eq 0 ]; then
    log_message "IPTABLES включен в автозагрузку"
else
    log_message "Ошибка включения IPTABLES в автозагрузку"
fi

echo "Раздача ключей"
log_message "Генерация SSH-ключа"
ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa -q
if [ $? -eq 0 ]; then
    log_message "SSH-ключ успешно сгенерирован"
else
    log_message "Ошибка генерации SSH-ключа"
fi

log_message "Добавление ключей хостов в known_hosts"
ssh-keyscan -H 172.16.1.4 >> ~/.ssh/known_hosts
ssh-keyscan -H 172.16.2.5 >> ~/.ssh/known_hosts
log_message "Ключи хостов добавлены в known_hosts"

log_message "Установка sshpass"
apt-get install sshpass -y
if [ $? -eq 0 ]; then
    log_message "sshpass успешно установлен"
else
    log_message "Ошибка установки sshpass"
fi

log_message "Копирование SSH-ключа на удаленные хосты"
sshpass -p 'admin' ssh-copy-id admin@172.16.1.4
if [ $? -eq 0 ]; then
    log_message "Ключ скопирован на 172.16.1.4"
else
    log_message "Ошибка копирования ключа на 172.16.1.4"
fi

sshpass -p 'admin' ssh-copy-id admin@172.16.2.5
if [ $? -eq 0 ]; then
    log_message "Ключ скопирован на 172.16.2.5"
else
    log_message "Ошибка копирования ключа на 172.16.2.5"
fi

echo "Настройка HQ-RTR|BR-RTR-Коммутация"
log_message "Переход в директорию DEMO-2025-testing"
cd DEMO-2025-testing
if [ $? -eq 0 ]; then
    log_message "Успешно перешли в DEMO-2025-testing"
else
    log_message "Ошибка перехода в DEMO-2025-testing"
fi

log_message "Обновление пакетов"
apt-get update
log_message "Пакеты обновлены"

log_message "Установка expect"
apt-get install expect -y
if [ $? -eq 0 ]; then
    log_message "Expect успешно установлен"
else
    log_message "Ошибка установки expect"
fi

log_message "Включение SSH сервера"
systemctl enable --now sshd
if [ $? -eq 0 ]; then
    log_message "SSH сервер включен"
else
    log_message "Ошибка включения SSH сервера"
fi

log_message "Запуск expect скриптов"
expect hq-rtr-module-1.exp
if [ $? -eq 0 ]; then
    log_message "hq-rtr-module-1.exp выполнен успешно"
else
    log_message "Ошибка выполнения hq-rtr-module-1.exp"
fi

expect br-rtr-module-1.exp
if [ $? -eq 0 ]; then
    log_message "br-rtr-module-1.exp выполнен успешно"
else
    log_message "Ошибка выполнения br-rtr-module-1.exp"
fi

echo "Окончательная раздача ключей"
log_message "Добавление ключей для альтернативных портов"
ssh-keyscan -p 2026 172.16.1.4 >> ~/.ssh/known_hosts
ssh-keyscan -p 2026 172.16.2.5 >> ~/.ssh/known_hosts
ssh-keyscan -p 2222 172.16.1.4 >> ~/.ssh/known_hosts
log_message "Ключи для альтернативных портов добавлены"

log_message "Копирование ключей на root пользователей"
sshpass -p 'toor' ssh-copy-id -p 2026 root@172.16.2.5
if [ $? -eq 0 ]; then
    log_message "Ключ скопирован на root@172.16.2.5:2026"
else
    log_message "Ошибка копирования ключа на root@172.16.2.5:2026"
fi

sshpass -p 'toor' ssh-copy-id -p 2026 root@172.16.1.4
if [ $? -eq 0 ]; then
    log_message "Ключ скопирован на root@172.16.1.4:2026"
else
    log_message "Ошибка копирования ключа на root@172.16.1.4:2026"
fi

sshpass -p 'toor' ssh-copy-id -p 2222 root@172.16.1.4
if [ $? -eq 0 ]; then
    log_message "Ключ скопирован на root@172.16.1.4:2222"
else
    log_message "Ошибка копирования ключа на root@172.16.1.4:2222"
fi

echo "Смена название машины"
log_message "Смена hostname на удаленных машинах"
echo "hostnamectl set-hostname hq-srv.au-team.irpo; exec bash" | sshpass -p 'toor' ssh -p 2026 root@172.16.1.4
if [ $? -eq 0 ]; then
    log_message "Hostname изменен на hq-srv.au-team.irpo (172.16.1.4:2026)"
else
    log_message "Ошибка смены hostname на 172.16.1.4:2026"
fi

echo "hostnamectl set-hostname hq-cli.au-team.irpo; exec bash" | sshpass -p 'toor' ssh -p 2222 root@172.16.1.4
if [ $? -eq 0 ]; then
    log_message "Hostname изменен на hq-cli.au-team.irpo (172.16.1.4:2222)"
else
    log_message "Ошибка смены hostname на 172.16.1.4:2222"
fi

echo "hostnamectl set-hostname br-srv.au-team.irpo; exec bash" | sshpass -p 'toor'  ssh -p 2026 root@172.16.2.5
if [ $? -eq 0 ]; then
    log_message "Hostname изменен на br-srv.au-team.irpo (172.16.2.5:2026)"
else
    log_message "Ошибка смены hostname на 172.16.2.5:2026"
fi

echo "Настройка DNS"
log_message "Запуск HQ-SRV-Launch.sh на удаленном хосте"
sshpass -p 'toor' ssh -p 2026 root@172.16.1.4 "bash -s" < HQ-SRV-Launch.sh
if [ $? -eq 0 ]; then
    log_message "HQ-SRV-Launch.sh выполнен успешно"
else
    log_message "Ошибка выполнения HQ-SRV-Launch.sh"
fi

echo "Настройка Samba"
log_message "Запуск samba-part-1.sh на удаленном хосте"
sshpass -p 'toor' ssh -p 2026 root@172.16.2.5 "bash -s" < samba-part-1.sh
if [ $? -eq 0 ]; then
    log_message "samba-part-1.sh выполнен успешно"
else
    log_message "Ошибка выполнения samba-part-1.sh"
fi

log_message "Настройка DNS на клиенте"
cat << EOF | sshpass -p 'toor' ssh -p 2222 root@172.16.1.4
sed -i 's/BOOTPROTO=static/BOOTPROTO=dhcp/' /etc/net/ifaces/ens20/options
systemctl restart network
EOF

if [ $? -eq 0 ]; then
    log_message "Изменён на DHCP тип у клиента, режим ошидания"
else
    log_message "Ошибка изменения."
fi

sleep 8

cat << EOF | sshpass -p 'toor' ssh -p 2222 root@172.16.1.4
apt-get update && apt-get install bind-utils -y
system-auth write ad AU-TEAM.IRPO cli AU-TEAM 'administrator' 'P@ssw0rd'
EOF

if [ $? -eq 0 ]; then
    log_message "DNS настройки применены на клиенте"
else
    log_message "Ошибка настройки DNS на клиенте"
fi

log_message "Перезагрузка клиента"
echo "reboot" | sshpass -p 'toor' ssh -p 2222 root@172.16.1.4
log_message "Клиент перезагружается"

log_message "Запуск samba-part-2.sh"
sshpass -p 'toor' ssh -p 2026 root@172.16.2.5 "bash -s" < samba-part-2.sh
if [ $? -eq 0 ]; then
    log_message "samba-part-2.sh выполнен успешно"
else
    log_message "Ошибка выполнения samba-part-2.sh"
fi

log_message "Ожидание 15 секунд"
sleep 15
log_message "Ожидание завершено"

log_message "Запуск cli-sssd-part1.sh"
sshpass -p 'toor' ssh -p 2222 root@172.16.1.4 "bash -s" < cli-sssd-part1.sh
if [ $? -eq 0 ]; then
    log_message "cli-sssd-part1.sh выполнен успешно"
else
    log_message "Ошибка выполнения cli-sssd-part1.sh"
fi

log_message "Ожидание 15 секунд"
sleep 15
log_message "Ожидание завершено"

log_message "Запуск cli-sssd-part2.sh"
sshpass -p 'toor' ssh -p 2222 root@172.16.1.4 "bash -s" < cli-sssd-part2.sh
if [ $? -eq 0 ]; then
    log_message "cli-sssd-part2.sh выполнен успешно"
else
    log_message "Ошибка выполнения cli-sssd-part2.sh"
fi

log_message "Ожидание 15 секунд"
sleep 15
log_message "Ожидание завершено"

log_message "Установка chrony"
apt-get install chrony -y
if [ $? -eq 0 ]; then
    log_message "Chrony успешно установлен"
else
    log_message "Ошибка установки chrony"
fi

log_message "Настройка chrony конфигурации"
cat << EOF > /etc/chrony.conf
server 127.0.0.1 iburst prefer
hwtimestamp *
local stratum 5
allow 0/0
EOF
log_message "Конфигурация chrony создана"

log_message "Включение chrony службы"
systemctl enable --now chronyd
if [ $? -eq 0 ]; then
    log_message "Chronyd включен и запущен"
else
    log_message "Ошибка включения chronyd"
fi

log_message "Настройка chrony на удаленных хостах"
cat << EOF | sshpass -p 'toor' ssh -p 2222 root@172.16.1.4
apt-get install chrony -y
echo -e 'server 172.16.1.4 iburst prefer' > /etc/chrony.conf
systemctl enable --now chronyd
EOF
if [ $? -eq 0 ]; then
    log_message "Chrony настроен на 172.16.1.4:2222"
else
    log_message "Ошибка настройки chrony на 172.16.1.4:2222"
fi

cat << EOF | sshpass -p 'toor' ssh -p 2026 root@172.16.1.4
apt-get install chrony -y
echo -e 'server 172.16.1.4 iburst prefer' > /etc/chrony.conf
systemctl enable --now chronyd
EOF
if [ $? -eq 0 ]; then
    log_message "Chrony настроен на 172.16.1.4:2026"
else
    log_message "Ошибка настройки chrony на 172.16.1.4:2026"
fi

cat << EOF | sshpass -p 'toor' ssh -p 2026 root@172.16.2.5
apt-get install chrony -y
echo -e 'server 172.16.2.5 iburst prefer' > /etc/chrony.conf
systemctl enable --now chronyd
EOF
if [ $? -eq 0 ]; then
    log_message "Chrony настроен на 172.16.2.5:2026"
else
    log_message "Ошибка настройки chrony на 172.16.2.5:2026"
fi

log_message "Смена hostname локальной машины"
hostnamectl set-hostname ISP
if [ $? -eq 0 ]; then
    log_message "Hostname изменен на ISP"
else
    log_message "Ошибка смены hostname на ISP"
fi

echo "exec bash"
log_message "Скрипт завершен успешно"
echo "Настройка ISP завершена"
