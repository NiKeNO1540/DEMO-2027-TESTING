#!/bin/bash

# Функция для логирования
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Файл для отслеживания прогресса
PROGRESS_FILE="/var/tmp/isp_setup_progress"
LOG_FILE="/var/tmp/isp_setup.log"

# Функция для проверки выполнения этапа
check_stage() {
    local stage=$1
    grep -q "STAGE_${stage}_COMPLETED" "$PROGRESS_FILE" 2>/dev/null
    return $?
}

# Функция для отметки выполнения этапа
mark_stage_completed() {
    local stage=$1
    echo "STAGE_${stage}_COMPLETED $(date '+%Y-%m-%d %H:%M:%S')" >> "$PROGRESS_FILE"
    log_message "Этап $stage отмечен как выполненный"
}

# Функция для создания резервной копии конфигурации
create_backup() {
    local stage=$1
    local backup_dir="/var/tmp/isp_backups"
    mkdir -p "$backup_dir"
    tar -czf "$backup_dir/backup_stage_${stage}_$(date '+%Y%m%d_%H%M%S').tar.gz" \
        /etc/net/ifaces/ /etc/sysconfig/iptables /root/.ssh/ /etc/chrony.conf /etc/nginx/ 2>/dev/null
    log_message "Создана резервная копия для этапа $stage"
}

# Инициализация файла прогресса если его нет
if [ ! -f "$PROGRESS_FILE" ]; then
    touch "$PROGRESS_FILE"
    log_message "Файл прогресса инициализирован: $PROGRESS_FILE"
fi

# ====== Управление шагами внутри этапа ======

# Проверка выполнения шага
check_step() {
    local stage=$1
    local step=$2
    grep -q "STAGE_${stage}_STEP_${step}_COMPLETED" "$PROGRESS_FILE" 2>/dev/null
    return $?
}

# Отметка выполнения шага
mark_step_completed() {
    local stage=$1
    local step=$2
    echo "STAGE_${stage}_STEP_${step}_COMPLETED $(date '+%Y-%m-%d %H:%M:%S')" >> "$PROGRESS_FILE"
    log_message "Шаг $step из этапа $stage отмечен как выполненный"
}

echo "Начало выполнения скрипта настройки ISP"
log_message "Старт скрипта настройки ISP (режим продолжения)"

# Этап 1: Настройка сетевых интерфейсов
if ! check_stage 1; then
    echo "=== Этап 1: Настройка ISP ==="
    log_message "Начало этапа 1: Настройка сетевых интерфейсов"
    
    log_message "Создание директорий для сетевых интерфейсов"
    apt-get reinstall tzdata -y
    timedatectl set-timezone Asia/Yekaterinburg
    mkdir -p /etc/net/ifaces/ens20
    mkdir -p /etc/net/ifaces/ens21
    log_message "Директории созданы: /etc/net/ifaces/ens21, /etc/net/ifaces/ens22"

    log_message "Создание конфигурационных файлов для сетевых интерфейсов"
    echo -e "BOOTPROTO=static\nTYPE=eth\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens20/options
    echo -e "BOOTPROTO=static\nTYPE=eth\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens21/options
    log_message "Конфигурационные файлы options созданы"

    log_message "Назначение IP-адресов интерфейсам"
    echo "172.16.1.1/28" > /etc/net/ifaces/ens20/ipv4address
    echo "172.16.2.1/28" > /etc/net/ifaces/ens21/ipv4address
    log_message "IP-адреса назначены: ens21=172.16.1.1/28, ens22=172.16.2.1/28"

    log_message "Перезапуск сетевой службы"
    systemctl restart network
    if [ $? -eq 0 ]; then
        log_message "Сетевая служба перезапущена"
        create_backup 1
        mark_stage_completed 1
    else
        log_message "Ошибка перезапуска сетевой службы"
        exit 1
    fi
else
    log_message "Этап 1 уже выполнен, пропускаем"
fi

# Этап 2: Настройка IPTABLES
if ! check_stage 2; then
    echo "=== Этап 2: Настройка IPTABLES ==="
    log_message "Начало этапа 2: Настройка IPTABLES"
    
    log_message "Установка iptables"
    apt-get install iptables -y
    if [ $? -eq 0 ]; then
        log_message "IPTABLES успешно установлен"
    else
        log_message "Ошибка установки IPTABLES"
    fi

    log_message "Настройка правил NAT"
    iptables -t nat -A POSTROUTING -o ens19 -s 172.16.1.0/28 -j MASQUERADE
    iptables -t nat -A POSTROUTING -o ens19 -s 172.16.2.0/28 -j MASQUERADE
    log_message "Правила NAT добавлены"

    log_message "Сохранение правил iptables"
    iptables-save > /etc/sysconfig/iptables
    log_message "Правила сохранены в /etc/sysconfig/iptables"

    log_message "Включение автозагрузки iptables"
    systemctl enable --now iptables
    if [ $? -eq 0 ]; then
        log_message "IPTABLES включен в автозагрузку"
        create_backup 2
        mark_stage_completed 2
    else
        log_message "Ошибка включения IPTABLES в автозагрузку"
    fi
else
    log_message "Этап 2 уже выполнен, пропускаем"
fi

# Этап 3: Генерация и раздача SSH ключей
if ! check_stage 3; then
    echo "=== Этап 3: Раздача ключей ==="
    log_message "Начало этапа 3: Генерация и раздача SSH ключей"
    
    log_message "Генерация SSH-ключа"
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa -q
        if [ $? -eq 0 ]; then
            log_message "SSH-ключ успешно сгенерирован"
        else
            log_message "Ошибка генерации SSH-ключа"
        fi
    else
        log_message "SSH-ключ уже существует, пропускаем генерацию"
    fi

    log_message "Добавление ключей хостов в known_hosts"
    grep -q "172.16.1.4" ~/.ssh/known_hosts 2>/dev/null || ssh-keyscan -H 172.16.1.4 >> ~/.ssh/known_hosts
    grep -q "172.16.2.5" ~/.ssh/known_hosts 2>/dev/null || ssh-keyscan -H 172.16.2.5 >> ~/.ssh/known_hosts
    log_message "Ключи хостов добавлены в known_hosts"

    log_message "Установка sshpass"
    if ! command -v sshpass &> /dev/null; then
        apt-get install sshpass -y
        if [ $? -eq 0 ]; then
            log_message "sshpass успешно установлен"
        else
            log_message "Ошибка установки sshpass"
        fi
    else
        log_message "sshpass уже установлен"
    fi

    log_message "Копирование SSH-ключа на удаленные хосты"
    sshpass -p 'admin' ssh-copy-id -o ConnectTimeout=10 admin@172.16.1.4 2>/dev/null
    if [ $? -eq 0 ]; then
        log_message "Ключ скопирован на 172.16.1.4"
    else
        log_message "Ошибка копирования ключа на 172.16.1.4"
    fi

    sshpass -p 'admin' ssh-copy-id -o ConnectTimeout=10 admin@172.16.2.5 2>/dev/null
    if [ $? -eq 0 ]; then
        log_message "Ключ скопирован на 172.16.2.5"
    else
        log_message "Ошибка копирования ключа на 172.16.2.5"
    fi
    
    create_backup 3
    mark_stage_completed 3
else
    log_message "Этап 3 уже выполнен, пропускаем"
fi

# Этап 4: Настройка маршрутизаторов
if ! check_stage 4; then
    echo "=== Этап 4: Настройка HQ-RTR|BR-RTR-Коммутация ==="
    log_message "Начало этапа 4: Настройка маршрутизаторов"
    
    log_message "Переход в директорию DEMO-2025-testing"
    if [ -d "DEMO-2025-testing" ]; then
        cd DEMO-2025-testing
        if [ $? -eq 0 ]; then
            log_message "Успешно перешли в DEMO-2025-testing"
        else
            log_message "Ошибка перехода в DEMO-2025-testing"
        fi
    else
        log_message "Директория DEMO-2025-testing не найдена"
    fi

    log_message "Обновление пакетов"
    apt-get update
    log_message "Пакеты обновлены"

    log_message "Установка expect"
    if ! command -v expect &> /dev/null; then
        apt-get install expect -y
        if [ $? -eq 0 ]; then
            log_message "Expect успешно установлен"
        else
            log_message "Ошибка установки expect"
        fi
    else
        log_message "Expect уже установлен"
    fi

    log_message "Включение SSH сервера"
    systemctl enable --now sshd
    if [ $? -eq 0 ]; then
        log_message "SSH сервер включен"
    else
        log_message "Ошибка включения SSH сервера"
    fi

    log_message "Запуск expect скриптов"
    if [ -f "hq-rtr-module-1.exp" ]; then
        expect hq-rtr-module-1.exp
        if [ $? -eq 0 ]; then
            log_message "hq-rtr-module-1.exp выполнен успешно"
        else
            log_message "Ошибка выполнения hq-rtr-module-1.exp"
        fi
    fi

    if [ -f "br-rtr-module-1.exp" ]; then
        expect br-rtr-module-1.exp
        if [ $? -eq 0 ]; then
            log_message "br-rtr-module-1.exp выполнен успешно"
        else
            log_message "Ошибка выполнения br-rtr-module-1.exp"
        fi
    fi
    
    create_backup 4
    mark_stage_completed 4
else
    log_message "Этап 4 уже выполнен, пропускаем"
fi

# Этап 5: Окончательная раздача ключей
if ! check_stage 5; then
    echo "=== Этап 5: Окончательная раздача ключей ==="
    log_message "Начало этапа 5: Окончательная раздача ключей"
    
    log_message "Добавление ключей для альтернативных портов"
    grep -q "172.16.1.4:2026" ~/.ssh/known_hosts 2>/dev/null || ssh-keyscan -p 2026 172.16.1.4 >> ~/.ssh/known_hosts
    grep -q "172.16.2.5:2026" ~/.ssh/known_hosts 2>/dev/null || ssh-keyscan -p 2026 172.16.2.5 >> ~/.ssh/known_hosts
    grep -q "172.16.1.4:2222" ~/.ssh/known_hosts 2>/dev/null || ssh-keyscan -p 2222 172.16.1.4 >> ~/.ssh/known_hosts
    log_message "Ключи для альтернативных портов добавлены"

    log_message "Копирование ключей на root пользователей"
    sshpass -p 'toor' ssh-copy-id -p 2026 -o ConnectTimeout=10 root@172.16.2.5 2>/dev/null
    if [ $? -eq 0 ]; then
        log_message "Ключ скопирован на root@172.16.2.5:2026"
    else
        log_message "Ошибка копирования ключа на root@172.16.2.5:2026"
    fi

    sshpass -p 'toor' ssh-copy-id -p 2026 -o ConnectTimeout=10 root@172.16.1.4 2>/dev/null
    if [ $? -eq 0 ]; then
        log_message "Ключ скопирован на root@172.16.1.4:2026"
    else
        log_message "Ошибка копирования ключа на root@172.16.1.4:2026"
    fi

    sshpass -p 'toor' ssh-copy-id -p 2222 -o ConnectTimeout=10 root@172.16.1.4 2>/dev/null
    if [ $? -eq 0 ]; then
        log_message "Ключ скопирован на root@172.16.1.4:2222"
    else
        log_message "Ошибка копирования ключа на root@172.16.1.4:2222"
    fi
    
    create_backup 5
    mark_stage_completed 5
else
    log_message "Этап 5 уже выполнен, пропускаем"
fi

# Этап 6: Смена hostname удаленных машин
if ! check_stage 6; then
    echo "=== Этап 6: Смена названия машины ==="
    log_message "Начало этапа 6: Смена hostname удаленных машин"
    
    log_message "Смена hostname на удаленных машинах"
    echo "hostnamectl set-hostname hq-srv.au-team.irpo" | sshpass -p 'toor' ssh -t -p 2026 -o ConnectTimeout=10 root@172.16.1.4
    if [ $? -eq 0 ]; then
        log_message "Hostname изменен на hq-srv.au-team.irpo (172.16.1.4:2026)"
    else
        log_message "Ошибка смены hostname на 172.16.1.4:2026"
    fi

    echo "hostnamectl set-hostname hq-cli.au-team.irpo" | sshpass -p 'toor' ssh -t -p 2222 -o ConnectTimeout=10 root@172.16.1.4
    if [ $? -eq 0 ]; then
        log_message "Hostname изменен на hq-cli.au-team.irpo (172.16.1.4:2222)"
    else
        log_message "Ошибка смены hostname на 172.16.1.4:2222"
    fi

    echo "hostnamectl set-hostname br-srv.au-team.irpo" | sshpass -p 'toor' ssh -t -p 2026 -o ConnectTimeout=10 root@172.16.2.5
    if [ $? -eq 0 ]; then
        log_message "Hostname изменен на br-srv.au-team.irpo (172.16.2.5:2026)"
    else
        log_message "Ошибка смены hostname на 172.16.2.5:2026"
    fi
    
    mark_stage_completed 6
else
    log_message "Этап 6 уже выполнен, пропускаем"
fi

# Этап 7: Настройка DNS и Samba
# ====== Настройки ======
STATUS_FILE=".stage_status"

check_step() {
    local step="$1"
    grep -q "^$step\$" "$STATUS_FILE" 2>/dev/null
}

mark_step_completed() {
    local step="$1"
    echo "$step" >> "$STATUS_FILE"
}

# ====== Этап 7: Настройка DNS и Samba ======
if ! check_stage 7; then
    echo "=== Этап 7: Настройка DNS и Samba ==="
    log_message "Начало этапа 7: Настройка DNS и Samba"

    # --- Шаг 7.1 Запуск HQ-SRV-Launch.sh ---
    if ! check_step "7.1_HQ-SRV-Launch"; then
        log_message "Запуск HQ-SRV-Launch.sh на удаленном хосте"
        if [ -f "HQ-SRV-Launch.sh" ]; then
            sshpass -p 'toor' ssh -t -p 2026 -o ConnectTimeout=10 root@172.16.1.4 "bash -s" < HQ-SRV-Launch.sh
            if [ $? -eq 0 ]; then
                log_message "HQ-SRV-Launch.sh выполнен успешно"
                mark_step_completed "7.1_HQ-SRV-Launch"
            else
                log_message "Ошибка выполнения HQ-SRV-Launch.sh"
            fi
        fi
    else
        log_message "Шаг 7.1 уже выполнен, пропускаем"
    fi

    # --- Шаг 7.2 Запуск samba-part-1.sh ---
    if ! check_step "7.2_samba-part-1"; then
        log_message "Запуск samba-part-1.sh"
        if [ -f "samba-part-1.sh" ]; then
            sshpass -p 'toor' ssh -t -p 2026 -o ConnectTimeout=10 root@172.16.2.5 "bash -s" < samba-part-1.sh
            if [ $? -eq 0 ]; then
                log_message "samba-part-1.sh выполнен успешно"
                mark_step_completed "7.2_samba-part-1"
            else
                log_message "Ошибка выполнения samba-part-1.sh"
            fi
        fi
    else
        log_message "Шаг 7.2 уже выполнен, пропускаем"
    fi

    # --- Шаг 7.3 Настройка клиента на DHCP ---
    if ! check_step "7.3_set-dhcp"; then
        log_message "Настройка DNS: переключение клиента в DHCP"
        cat << EOF | sshpass -p 'toor' ssh -p 2222 -o ConnectTimeout=10 root@172.16.1.4
sed -i 's/BOOTPROTO=static/BOOTPROTO=dhcp/' /etc/net/ifaces/ens19/options
systemctl restart network
EOF
        if [ $? -eq 0 ]; then
            log_message "Клиент переведён в DHCP"
            mark_step_completed "7.3_set-dhcp"
        else
            log_message "Ошибка при переключении клиента в DHCP"
        fi
    else
        log_message "Шаг 7.3 уже выполнен"
    fi

    # --- Шаг 7.4 DNS настройка клиента ---
    if ! check_step "7.4_dns-client"; then
        sleep 8
        log_message "Настройка DNS на клиенте"
        cat << EOF | sshpass -p 'toor' ssh -p 2222 -o ConnectTimeout=10 root@172.16.1.4
apt-get update && apt-get install bind-utils admc yandex-browser -y
system-auth write ad AU-TEAM.IRPO cli AU-TEAM 'administrator' 'P@ssw0rd'
hostnamectl set-hostname hq-cli.au-team.irpo
EOF
        if [ $? -eq 0 ]; then
            log_message "DNS настройки успешно применены"
            mark_step_completed "7.4_dns-client"
        else
            log_message "Ошибка настройки DNS"
        fi
    else
        log_message "Шаг 7.4 уже выполнен"
    fi

    # --- Шаг 7.5 Перезагрузка клиента ---
    if ! check_step "7.5_reboot-client"; then
        log_message "Перезагрузка клиента"
        echo "reboot" | sshpass -p 'toor' ssh -p 2222 -o ConnectTimeout=5 root@172.16.1.4
        log_message "Клиент перезагружается, ожидание 30 секунд"
        sleep 30
        mark_step_completed "7.5_reboot-client"
    else
        log_message "Шаг 7.5 уже выполнен"
    fi

    # --- Шаг 7.6 samba-part-2 ---
    if ! check_step "7.6_samba-part-2"; then
        log_message "Запуск samba-part-2.sh"
        if [ -f "samba-part-2.sh" ]; then
            sshpass -p 'toor' ssh -p 2026 -o ConnectTimeout=10 root@172.16.2.5 "bash -s" < samba-part-2.sh
            if [ $? -eq 0 ]; then
                log_message "samba-part-2.sh выполнен успешно"
                mark_step_completed "7.6_samba-part-2"
            else
                log_message "Ошибка выполнения samba-part-2.sh"
            fi
        fi
        sleep 15
    else
        log_message "Шаг 7.6 уже выполнен"
    fi

    # --- Шаг 7.7 cli-sssd-part1 ---
    if ! check_step "7.7_cli-sssd-part1"; then
        log_message "Запуск cli-sssd-part1.sh"
        if [ -f "cli-sssd-part1.sh" ]; then
            sshpass -p 'toor' ssh -t -p 2222 -o ConnectTimeout=10 root@172.16.1.4 "bash -s" < cli-sssd-part1.sh
            echo "reboot" | sshpass -p 'toor' ssh -p 2222 -o ConnectTimeout=5 root@172.16.1.4
            if [ $? -eq 0 ]; then
                log_message "cli-sssd-part1.sh выполнен успешно"
                mark_step_completed "7.7_cli-sssd-part1"
            else
                log_message "Ошибка cli-sssd-part1.sh"
            fi
        fi
        sleep 15
    else
        log_message "Шаг 7.7 уже выполнен"
    fi

    # --- Шаг 7.8 cli-sssd-part2 ---
    if ! check_step "7.8_cli-sssd-part2"; then
        log_message "Запуск cli-sssd-part2.sh"
        if [ -f "cli-sssd-part2.sh" ]; then
            sshpass -p 'toor' ssh -t -p 2222 -o ConnectTimeout=10 root@172.16.1.4 "bash -s" < cli-sssd-part2.sh
            if [ $? -eq 0 ]; then
                log_message "cli-sssd-part2.sh выполнен успешно"
                mark_step_completed "7.8_cli-sssd-part2"
            else
                log_message "Ошибка cli-sssd-part2.sh"
            fi
        fi
        sleep 15
    else
        log_message "Шаг 7.8 уже выполнен"
    fi

    # Помечаем этап 7 целиком
    mark_stage_completed 7
else
    log_message "Этап 7 уже выполнен ранее, пропускаем"
fi

# Этап 8: Настройка Chrony
if ! check_stage 8; then
    echo "=== Этап 8: Настройка Chrony ==="
    log_message "Начало этапа 8: Настройка Chrony"
    
    log_message "Установка chrony"
    if ! command -v chronyd &> /dev/null; then
        apt-get install chrony -y
        if [ $? -eq 0 ]; then
            log_message "Chrony успешно установлен"
        else
            log_message "Ошибка установки chrony"
        fi
    else
        log_message "Chrony уже установлен"
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
    systemctl restart chronyd
    if [ $? -eq 0 ]; then
        log_message "Chronyd включен и запущен"
    else
        log_message "Ошибка включения chronyd"
    fi

    log_message "Настройка chrony на удаленных хостах"
    cat << EOF | sshpass -p 'toor' ssh -t -p 2222 -o ConnectTimeout=10 root@172.16.1.4
which chronyd >/dev/null 2>&1 || apt-get install chrony -y
echo -e 'server 172.16.1.1 iburst prefer' > /etc/chrony.conf
systemctl enable --now chronyd
systemctl restart chronyd
sleep 5
timedatectl
EOF
    if [ $? -eq 0 ]; then
        log_message "Chrony настроен на 172.16.1.4:2222"
    else
        log_message "Ошибка настройки chrony на 172.16.1.4:2222"
    fi

    cat << EOF | sshpass -p 'toor' ssh -t -p 2026 -o ConnectTimeout=10 root@172.16.1.4
which chronyd >/dev/null 2>&1 || apt-get install chrony -y
echo -e 'server 172.16.1.1 iburst prefer' > /etc/chrony.conf
systemctl enable --now chronyd
systemctl restart chronyd
sleep 5
timedatectl
EOF
    if [ $? -eq 0 ]; then
        log_message "Chrony настроен на 172.16.1.4:2026"
    else
        log_message "Ошибка настройки chrony на 172.16.1.4:2026"
    fi

    cat << EOF | sshpass -p 'toor' ssh -t -p 2026 -o ConnectTimeout=10 root@172.16.2.5
which chronyd >/dev/null 2>&1 || apt-get install chrony -y
echo -e 'server 172.16.2.1 iburst prefer' > /etc/chrony.conf
systemctl enable --now chronyd
systemctl restart chronyd
sleep 5
timedatectl
EOF
    if [ $? -eq 0 ]; then
        log_message "Chrony настроен на 172.16.2.5:2026"
    else
        log_message "Ошибка настройки chrony на 172.16.2.5:2026"
    fi
    
    create_backup 8
    mark_stage_completed 8
else
    log_message "Этап 8 уже выполнен, пропускаем"
fi

# Этап 9: Настройка RAID
if ! check_stage 9; then
    echo "=== Этап 9: Добавление RAID ==="
    log_message "Начало этапа 9: Настройка RAID массивов"
    
    log_message "Настройка RAID на HQ-SRV"
    if [ -f "Raid-HQ-SRV.sh" ]; then
        sshpass -p 'toor' ssh -t -p 2026 -o ConnectTimeout=10 root@172.16.1.4 "bash -s" < Raid-HQ-SRV.sh
        if [ $? -eq 0 ]; then
            log_message "Raid-HQ-SRV.sh выполнен успешно"
        else
            log_message "Ошибка выполнения Raid-HQ-SRV.sh"
        fi
    else
        log_message "Файл Raid-HQ-SRV.sh не найден"
    fi

    log_message "Настройка RAID на HQ-CLI"
    if [ -f "Raid-HQ-CLI.sh" ]; then
        sshpass -p 'toor' ssh -t -p 2222 -o ConnectTimeout=10 root@172.16.1.4 "bash -s" < Raid-HQ-CLI.sh
        if [ $? -eq 0 ]; then
            log_message "Raid-HQ-CLI.sh выполнен успешно"
        else
            log_message "Ошибка выполнения Raid-HQ-CLI.sh"
        fi
    else
        log_message "Файл Raid-HQ-CLI.sh не найден"
    fi

    log_message "Ожидание 10 секунд для завершения настройки RAID"
    sleep 10
    
    mark_stage_completed 9
else
    log_message "Этап 9 уже выполнен, пропускаем"
fi

# Этап 10: Настройка Ansible на BR-SRV
if ! check_stage 10; then
    echo "=== Этап 10: Добавление Ansible на BR-SRV ==="
    log_message "Начало этапа 10: Настройка Ansible на BR-SRV"
    
    log_message "Установка Ansible на BR-SRV"
    if [ -f "Ansible-BR-SRV.sh" ]; then
        sshpass -p 'toor' ssh -t -p 2026 -o ConnectTimeout=10 root@172.16.2.5 "bash -s" < Ansible-BR-SRV.sh
        if [ $? -eq 0 ]; then
            log_message "Ansible-BR-SRV.sh выполнен успешно"
        else
            log_message "Ошибка выполнения Ansible-BR-SRV.sh"
        fi
    else
        log_message "Файл Ansible-BR-SRV.sh не найден"
    fi

    log_message "Ожидание 5 секунд для завершения установки Ansible"
    sleep 5
    
    mark_stage_completed 10
else
    log_message "Этап 10 уже выполнен, пропускаем"
fi

# Этап 11: Настройка Docker на BR-SRV
if ! check_stage 11; then
    echo "=== Этап 11: Добавление Docker на BR-SRV ==="
    log_message "Начало этапа 11: Настройка Docker на BR-SRV"
    
    log_message "Копирование site.yml на BR-SRV"
    if [ -f "site.yml" ]; then
        scp -P 2026 -o ConnectTimeout=10 site.yml root@172.16.2.5:/root/site.yml
        if [ $? -eq 0 ]; then
            log_message "site.yml успешно скопирован на BR-SRV"
        else
            log_message "Ошибка копирования site.yml на BR-SRV"
        fi
    else
        log_message "Файл site.yml не найден"
    fi

    log_message "Установка Docker на BR-SRV"
    if [ -f "docker.sh" ]; then
        sshpass -p 'toor' ssh -t -p 2026 -o ConnectTimeout=10 root@172.16.2.5 "bash -s" < docker.sh
        if [ $? -eq 0 ]; then
            log_message "docker.sh выполнен успешно"
        else
            log_message "Ошибка выполнения docker.sh"
        fi
    else
        log_message "Файл docker.sh не найден"
    fi

    if [ -f "docker-br-srv.exp" ]; then
        expect docker-br-srv.exp
        if [ $? -eq 0 ]; then
            log_message "docker-br-srv.exp выполнен успешно"
        else
            log_message "Ошибка выполнения docker-br-srv.exp"
        fi
    else
        log_message "Файл docker-br-srv.exp не найден"
    fi

    log_message "Ожидание 10 секунд для завершения установки Docker"
    sleep 10
    
    mark_stage_completed 11
else
    log_message "Этап 11 уже выполнен, пропускаем"
fi

# Этап 12: Настройка сайта на HQ-SRV
if ! check_stage 12; then
    echo "=== Этап 12: Добавление Сайта на HQ-SRV ==="
    log_message "Начало этапа 12: Настройка сайта на HQ-SRV"
    
    log_message "Установка сайта на HQ-SRV"
    if [ -f "site.sh" ]; then
        sshpass -p 'toor' ssh -t -p 2026 -o ConnectTimeout=10 root@172.16.1.4 "bash -s" < site.sh
        if [ $? -eq 0 ]; then
            log_message "site.sh выполнен успешно"
        else
            log_message "Ошибка выполнения site.sh"
        fi
    else
        log_message "Файл site.sh не найден"
    fi

    log_message "Ожидание 10 секунд для завершения настройки сайта"
    sleep 10
    
    mark_stage_completed 12
else
    log_message "Этап 12 уже выполнен, пропускаем"
fi

# Этап 13: Настройка NGINX на ISP
if ! check_stage 13; then
    echo "=== Этап 13: Добавление NGINX, Web-Based Auth на ISP ==="
    log_message "Начало этапа 13: Настройка NGINX прокси на ISP"
    
    log_message "Установка nginx и apache2-utils"
    apt-get install nginx -y
    apt-get install apache2-htpasswd -y
    if [ $? -eq 0 ]; then
        log_message "nginx и apache2-utils успешно установлены"
    else
        log_message "Ошибка установки nginx и apache2-utils"
    fi

    log_message "Создание файла аутентификации"
    htpasswd -bc /etc/nginx/.htpasswd WEB P@ssw0rd
    if [ $? -eq 0 ]; then
        log_message "Файл аутентификации создан: /etc/nginx/.htpasswd"
    else
        log_message "Ошибка создания файла аутентификации"
    fi

    log_message "Создание директорий для конфигурации nginx"
    mkdir -p /etc/nginx/sites-available.d
    mkdir -p /etc/nginx/sites-enabled.d

    log_message "Создание конфигурации nginx прокси"
    cat << EOF > /etc/nginx/sites-available.d/proxy.conf
server {
    listen 80;
    server_name web.au-team.irpo;
    
    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
    
    location / {
        proxy_pass http://172.16.2.5:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}

server {
    listen 80;
    server_name docker.au-team.irpo;
    
    location / {
        proxy_pass http://172.16.1.4:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
    log_message "Конфигурация nginx создана"

    log_message "Активация конфигурации nginx"
    if [ -f "/etc/nginx/sites-available.d/default.conf" ]; then
        mv /etc/nginx/sites-available.d/default.conf /root/
        log_message "Дефолтный конфиг перемещен в /root/"
    fi

    ln -sf /etc/nginx/sites-available.d/proxy.conf /etc/nginx/sites-enabled.d/
    if [ $? -eq 0 ]; then
        log_message "Симлинк конфигурации создан"
    else
        log_message "Ошибка создания симлинка конфигурации"
    fi

    log_message "Проверка конфигурации nginx"
    nginx -t
    if [ $? -eq 0 ]; then
        log_message "Конфигурация nginx проверена успешно"
    else
        log_message "Ошибка в конфигурации nginx"
    fi

    log_message "Включение и запуск nginx"
    systemctl enable --now nginx
    systemctl restart nginx
    if [ $? -eq 0 ]; then
        log_message "nginx успешно запущен"
    else
        log_message "Ошибка запуска nginx"
    fi

    create_backup 13
    mark_stage_completed 13
else
    log_message "Этап 13 уже выполнен, пропускаем"
fi

# Этап 14: Установка Yandex Browser на HQ-CLI
if ! check_stage 14; then
    echo "=== Этап 14: Добавление Yandex Browser на HQ-CLI ==="
    log_message "Начало этапа 14: Установка Yandex Browser на HQ-CLI"
    
    log_message "Установка Yandex Browser на HQ-CLI"
    echo "apt-get update && apt-get install yandex-browser -y" | sshpass -p 'toor' ssh -t -p 2222 -o ConnectTimeout=10 root@172.16.1.4
    if [ $? -eq 0 ]; then
        log_message "Yandex Browser успешно установлен на HQ-CLI"
    else
        log_message "Ошибка установки Yandex Browser на HQ-CLI"
    fi
    
    mark_stage_completed 14
else
    log_message "Этап 14 уже выполнен, пропускаем"
fi

# Этап 15: Финальные настройки
if ! check_stage 15; then
    echo "=== Этап 15: Финальные настройки ==="
    log_message "Начало этапа 15: Финальные настройки"
    
    log_message "Смена hostname локальной машины"
    hostnamectl set-hostname ISP
    if [ $? -eq 0 ]; then
        log_message "Hostname изменен на ISP"
    else
        log_message "Ошибка смены hostname на ISP"
    fi

    # Проверка копирования ключа на hquser1 (повторная попытка если нужно)
    log_message "Попытка копирования ключа на hquser1"
    sshpass -p 'P@ssw0rd' ssh-copy-id -p 2222 -o ConnectTimeout=10 hquser1@172.16.1.4 2>/dev/null
    if [ $? -eq 0 ]; then
        log_message "Ключ скопирован на hquser1@172.16.1.4:2222"
    else
        log_message "Ошибка копирования ключа на hquser1@172.16.1.4:2222"
    fi

    log_message "Проверка прав доступа"
    cat << EOF | sshpass -p 'P@ssw0rd' ssh -p 2222 -o ConnectTimeout=10 hquser1@172.16.1.4 2>/dev/null
sudo cat /etc/passwd | grep root && sudo id root
EOF
    if [ $? -eq 0 ]; then
        log_message "Права доступа проверены"
    else
        log_message "Ошибка проверки прав доступа"
    fi


    cat << EOF | sshpass -p 'toor' ssh -p 2026 root@172.16.1.4
    echo -e 'AllowUsers sshuser\nMaxAuthTries 2\nBanner /root/banner' >> /etc/openssh/sshd_config
    echo 'Authorized Access Only' > /root/banner
    sed -i 's/# WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL/WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
    if ! id sshuser | grep wheel; then
    gpasswd -a 'sshuser' wheel
    fi
    systemctl restart sshd
EOF

    cat << EOF | sshpass -p 'toor' ssh -p 2026 root@172.16.2.5
    echo -e 'AllowUsers sshuser\nMaxAuthTries 2\nBanner /root/banner' >> /etc/openssh/sshd_config
    echo 'Authorized Access Only' > /root/banner
    sed -i 's/# WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL/WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
    if ! id sshuser | grep wheel; then
    gpasswd -a 'sshuser' wheel
    fi
    systemctl restart sshd
EOF
else
    log_message "Этап 15 уже выполнен, пропускаем"
fi

echo "exec bash"
log_message "Скрипт завершен успешно"
echo "Настройка ISP завершена"

# Отображение сводки выполненных этапов
echo "=== Сводка выполненных этапов ==="
cat "$PROGRESS_FILE" 2>/dev/null || echo "Файл прогресса не найден"

log_message "Все этапы завершены. Скрипт можно перезапускать для продолжения с места остановки."
