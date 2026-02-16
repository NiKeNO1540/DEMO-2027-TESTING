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


## HQ-RTR | BR-RTR (Ecorouter)

- Базовая коммутация до ISP-a.

> Название пользователя: admin, пароль: admin

### HQ-RTR

```tcl
en
conf t
interface int0
description "to isp"
ip address 172.16.1.4/28
exit
port te0
service-instance te0/int0
encapsulation untagged
exit
exit
interface int0
connect port te0 service-instance te0/int0
exit
ip route 0.0.0.0 0.0.0.0 172.16.1.1
no security default
exit
wr
```

### BR-RTR

```tcl
en
conf t
interface int0
description "to isp"
ip address 172.16.2.5/28
exit
port te0
service-instance te0/int0
encapsulation untagged
exit
exit
interface int0
connect port te0 service-instance te0/int0
exit
ip route 0.0.0.0 0.0.0.0 172.16.2.1
no security default
exit
wr
```

## HQ-SRV | HQ-CLI | BR-SRV

- Базовая коммутация до роутеров.

> Название пользователя: root|user, Пароль: toor|resu (На HQ-SRV|BR-SRV root, на HQ-CLI user)

### HQ-SRV

```bash
mkdir -p /etc/net/ifaces/ens20
echo -e "DISABLED=no\nTYPE=eth\nBOOTPROTO=static\nCONFIG_IPv4=yes" > /etc/net/ifaces/ens20/options
echo "192.168.1.10/27" > /etc/net/ifaces/ens20/ipv4address
echo "default via 192.168.1.1" > /etc/net/ifaces/ens20/ipv4route
systemctl restart network
```

### HQ-CLI

```bash
mkdir -p /etc/net/ifaces/ens20
echo -e "DISABLED=no\nTYPE=eth\nBOOTPROTO=static\nCONFIG_IPv4=yes" > /etc/net/ifaces/ens20/options
echo "192.168.2.10/28" > /etc/net/ifaces/ens20/ipv4address
echo "default via 192.168.2.1" > /etc/net/ifaces/ens20/ipv4route
systemctl restart network
```

### BR-SRV

```bash
mkdir -p /etc/net/ifaces/ens20
echo -e "DISABLED=no\nTYPE=eth\nBOOTPROTO=static\nCONFIG_IPv4=yes" > /etc/net/ifaces/ens20/options
echo "192.168.3.10/28" > /etc/net/ifaces/ens20/ipv4address
echo "default via 192.168.3.1" > /etc/net/ifaces/ens20/ipv4route
systemctl restart network
```

- Разрешение на логирование через root(делайте только в случае автоматизации, в реальной жизни никто так делать конечно же не будет, всё сделано в целях автоматизации)

### BR-SRV | HQ-SRV 

```bash
echo -e "PermitRootLogin yes\nPort 2026" >> /etc/openssh/sshd_config
systemctl enable --now sshd
systemctl restart sshd
```

### HQ-CLI
```bash
echo -e "PermitRootLogin yes\nPort 2222" >> /etc/openssh/sshd_config
systemctl enable --now sshd
systemctl restart sshd
```

## ISP

- Настройка DHCP интерфейса

```bash
mkdir -p /etc/net/ifaces/ens20
echo -e "DISABLED=no\nTYPE=eth\nBOOTPROTO=dhcp\nCONFIG_IPv4=yes" > /etc/net/ifaces/ens20/options
echo "net.ipv4.ip_forward = 1" >> /etc/net/sysctl.conf
systemctl restart network
```

# Инструкция для активации ISP-a

```bash
apt-get update && apt-get install git -y && git clone https://github.com/NiKeNO1540/DEMO-2025-testing && chmod +x DEMO-2025-testing/Full_Config_Progression_AIO.sh && ./DEMO-2025-testing/Full_Config_Progression_AIO.sh
```
