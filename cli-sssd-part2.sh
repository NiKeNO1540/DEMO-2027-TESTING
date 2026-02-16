#! /bin/bash

rm -rf /var/lib/sss/db/*
sss_cache -E
systemctl restart sssd

sudo -l -U hquser1
