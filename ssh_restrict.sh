#! /bin/bash

if ! [ -f /root/.ssh/id_ed25519 ]; then
        ssh-keygen -t ed25519 -b 4096 -N "" -f /root/.ssh/id_ed25519 -q
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

