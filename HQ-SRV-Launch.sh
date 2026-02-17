#! /bin/bash

timedatectl set-timezone Asia/Yekaterinburg

echo nameserver 8.8.8.8 >> /etc/resolv.conf

apt-get update
apt-get install bind bind-utils -y
sed -i 's/listen-on { 127.0.0.1; };/listen-on { 192.168.1.10; };/' /var/lib/bind/etc/options.conf
sed -i 's/listen-on-v6 { ::1; };/listen-on-v6 { none; };/' /var/lib/bind/etc/options.conf
sed -i 's|//forwarders { };|forwarders { 8.8.8.8; };|' /var/lib/bind/etc/options.conf
sed -i 's|//allow-query { localnets; };|allow-query { any; };|' /var/lib/bind/etc/options.conf
sed -i 's|//allow-recursion { localnets; };|allow-recursion { any; };|' /var/lib/bind/etc/options.conf

tsig-keygen -a HMAC-MD5 samba-key >> /var/lib/bind/etc/named.conf

cat << EOF >> /var/lib/bind/etc/rfc1912.conf
zone "au-team.irpo" {
        type master;
        file "au-team.irpo";
        allow-update {
                key "samba-key";
                192.168.3.10;
                192.168.2.0/28;
        };
};

zone "1.168.192.in-addr.arpa" {
        type master;
        file "1.168.192.in-addr.arpa";
};

zone "2.168.192.in-addr.arpa" {
        type master;
        file "2.168.192.in-addr.arpa";
};
EOF

cd /var/lib/bind/etc/zone

cp empty au-team.irpo
cp empty 1.168.192.in-addr.arpa
cp empty 2.168.192.in-addr.arpa

sed -i '14d' au-team.irpo

cat << EOF >> au-team.irpo
@       IN      NS      hq-srv.au-team.irpo.
@       IN      A       192.168.3.10
hq-srv  IN      A       192.168.1.10
hq-rtr  IN      A       192.168.1.1
hq-cli  IN      A       192.168.2.10
br-rtr  IN      A       192.168.3.1
br-srv  IN      A       192.168.3.10
docker  IN      A       172.16.1.1
web     IN      A       172.16.2.1
EOF

sed -i '14d' 1.168.192.in-addr.arpa

cat << EOF >> 1.168.192.in-addr.arpa
@       IN      NS      hq-srv.au-team.irpo.
1       IN      PTR     hq-rtr.au-team.irpo.
10      IN      PTR     hq-srv.au-team.irpo.
EOF

sed -i '14d' 2.168.192.in-addr.arpa

cat << EOF >> 1.168.192.in-addr.arpa
@       IN      NS      hq-srv.au-team.irpo.
1       IN      PTR     hq-rtr.au-team.irpo.
10      IN      PTR     hq-cli.au-team.irpo.
EOF

rndc-confgen > /var/lib/bind/etc/rndc.key
sed -i ‘6,$d’ /var/lib/bind/etc/rndc.key

chown -R named:named /var/lib/bind/etc/zone/
chmod 755 /var/lib/bind/etc/zone/

chmod 644 au-team.irpo
chmod 644 1.168.192.in-addr.arpa
chmod 644 2.168.192.in-addr.arpa

systemctl enable --now bind
journalctl -xeu bind | grep -q 'sending notifies' && echo "Успешно" || echo "Неуспешно"

systemctl enable --now bind
