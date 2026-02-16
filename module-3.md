### Filter-map-ы

### HQ-RTR

```tcl
# Правило 10: Разрешаем ответный TCP-трафик (established connections)
filter-map ipv4 INTERNET_IN 10
match tcp any any ack
set accept
exit

# Правило 20: Разрешаем входящие подключения к сервисам
filter-map ipv4 INTERNET_IN 20
match tcp any any eq 80
match tcp any any eq 22
match tcp any any eq 443
match tcp any any eq 8080
match tcp any any eq 2026
match udp any host 192.168.2.10
match udp any host 192.168.1.10
match gre any any
match ospf any any
set accept
exit

# Правило 30: DNS (UDP + TCP для zone transfer)
filter-map ipv4 INTERNET_IN 30
match udp any any eq 53
match tcp any any eq 53
set accept
exit

# Правило 40: NTP (UDP!)
filter-map ipv4 INTERNET_IN 40
match udp any any eq 123
set accept
exit

# Правило 50: ICMP
filter-map ipv4 INTERNET_IN 50
match icmp any any
set accept
exit
```

### BR-RTR

```tcl
# Правило 10: Разрешаем ответный TCP-трафик (established connections)
filter-map ipv4 INTERNET_IN 10
match tcp any any ack
set accept
exit

# Правило 20: Разрешаем входящие подключения к сервисам
filter-map ipv4 INTERNET_IN 20
match tcp any any eq 80
match tcp any any eq 22
match tcp any any eq 443
match tcp any any eq 8080
match tcp any any eq 2026
match udp any host 192.168.3.10
match gre any any
match ospf any any
set accept
exit

# Правило 30: DNS (UDP + TCP для zone transfer)
filter-map ipv4 INTERNET_IN 30
match udp any any eq 53
match tcp any any eq 53
set accept
exit

# Правило 40: NTP (UDP!)
filter-map ipv4 INTERNET_IN 40
match udp any any eq 123
set accept
exit

# Правило 50: ICMP
filter-map ipv4 INTERNET_IN 50
match icmp any any
set accept
exit
```
