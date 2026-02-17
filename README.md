# Преднастройка

## ALTPve

### Монтирование образа.

- Зайти по айпи адресу, выдаваемый машиной, затем зайти в его хранилище > ISO Образы

<img width="1920" height="748" alt="image" src="https://github.com/user-attachments/assets/a4083415-18cf-4e71-a51f-33dbeaa14109" />

- Затем нужно загрузить образ, который требуется (В данном случае Additional.iso)

<img width="413" height="295" alt="image" src="https://github.com/user-attachments/assets/cf1eceba-1da3-482c-908e-2d96df4433c7" />

- Затем нужно вмонтировать этот образ в HQ-SRV и BR-SRV: Нужно нажать по конкретной машине -> Hardware, Add > CD|DVD drive -> Дальше всё как на скрине и нажать "ОК"

<img width="408" height="273" alt="image" src="https://github.com/user-attachments/assets/51cdb935-2c1a-4e8d-b71c-160bef934173" />

### Добавление дисков для raid

- PVE > HQ-SRV в Hardware > Add > Hard Disk > В пункте Storage выставляем local, размер диска 1 Gb > Добавляем всего 2 диска.

<img width="605" height="279" alt="image" src="https://github.com/user-attachments/assets/7e654fa2-ff0b-4521-9697-baffeab4a304" />


## HQ-RTR | BR-RTR (Alt JEos)

- Базовая коммутация до ISP-a.

> Название пользователя: root, пароль: toor

### HQ-RTR

```bash
echo -e "TYPE=eth" > /etc/net/ifaces/enp7s1/options
echo 172.16.1.10/28 > /etc/net/ifaces/enp7s1/ipv4address
echo default via 172.16.1.1 > /etc/net/ifaces/enp7s1/ipv4route
systemctl restart network
```

### BR-RTR

```bash
mkdir /etc/net/ifaces/enp7s2
echo 'TYPE=eth' > /etc/net/ifaces/enp7s1/options
echo 172.16.2.10/28 > /etc/net/ifaces/enp7s1/ipv4address
echo default via 172.16.2.1 > /etc/net/ifaces/enp7s1/ipv4route
systemctl restart network
```

## HQ-SRV | HQ-CLI | BR-SRV

- Базовая коммутация до роутеров.

> Название пользователя: root|user, Пароль: toor|resu (На HQ-SRV|BR-SRV root, на HQ-CLI user)

### HQ-SRV

```bash
echo 'TYPE=eth' > /etc/net/ifaces/enp7s1/options
echo 192.168.1.10/27 > /etc/net/ifaces/enp7s1/ipv4address
echo default via 192.168.1.1 > /etc/net/ifaces/enp7s1/ipv4route
systemctl restart network
```

### HQ-CLI

```bash
echo 'TYPE=eth' > /etc/net/ifaces/enp7s1/options 
echo 192.168.2.10/28 > /etc/net/ifaces/enp7s1/ipv4address
echo default via 192.168.2.1 > /etc/net/ifaces/enp7s1/ipv4route
systemctl restart network
```

### BR-SRV

```bash
echo 'TYPE=eth' > /etc/net/ifaces/enp7s1/options 
echo 192.168.3.10/28 > /etc/net/ifaces/enp7s1/ipv4address 
echo default via 192.168.3.1 > /etc/net/ifaces/enp7s1/ipv4route 
systemctl restart network
```

### BR-SRV | HQ-SRV 

- Разрешение на логирование через sshuser|net_admin по ssh
- Возможность использования sudo **без требования пароля** [Исключая HQ-RTR|BR-RTR]


```bash
echo -e "Port 2026\nAllowUsers sshuser" >> /etc/openssh/sshd_config
systemctl enable --now sshd
systemctl restart sshd
useradd sshuser -u 2026
echo -e "sshuser:P@ssw0rd" | chpasswd
visudo
# Пишите 140, потом Shift+G > Стрелка вправо > Нажать "D" затем стрелка вправо > :wq
gpasswd -a "sshuser" wheel
```

### HQ-CLI
```bash
echo -e "Port 2222\nAllowUsers sshuser" >> /etc/openssh/sshd_config
systemctl enable --now sshd
systemctl restart sshd
useradd sshuser
echo -e "sshuser:P@ssw0rd" | chpasswd
visudo
# Пишите 140, потом Shift+G > Стрелка вправо > Нажать "D" затем стрелка вправо > :wq
gpasswd -a "sshuser" wheel
```

### HQ-RTR | BR-RTR
```bash
echo -e "AllowUsers net_admin" >> /etc/openssh/sshd_config
systemctl enable --now sshd
systemctl restart sshd
useradd net_admin
echo -e "net_admin:P@ssw0rd" | chpasswd
usermod -aG wheel net_admin
id net_admin
```

# Инструкция для активации ISP-a

```bash
apt-get update && apt-get install git -y && git clone https://github.com/NiKeNO1540/DEMO-2027-testing && chmod +x DEMO-2027-testing/Full_Config_Progression_AIO.sh && ./DEMO-2027-testing/Full_Config_Progression_AIO.sh
```
