#!/bin/bash

web_service='haproxy'
config_file='/root/cli.ini'
domain=`grep "^\s*domains" $config_file | sed "s/^\s*domains\s*=\s*//" | sed 's/(\s*)\|,.*$//'`
combined_file="/etc/haproxy/certs/${domain}.pem"

exp_limit=30

if [ ! -f $config_file ]; then
    echo "[ERROR] config file does not exist: $config_file"
    exit 1;
fi

cert_file="/etc/letsencrypt/live/$domain/fullchain.pem"
key_file="/etc/letsencrypt/live/$domain/privkey.pem"

if [ ! -f $cert_file ]; then
    days_exp=0

else
    exp=$(date -d "`openssl x509 -in $cert_file -text -noout|grep "Not After"|cut -c 25-`" +%s)
    datenow=$(date -d "now" +%s)
    days_exp=$(echo \( $exp - $datenow \) / 86400 |bc)
fi

echo "Checking expiration date for $domain..."

if [ "$days_exp" -gt "$exp_limit" ] ; then
    echo "The certificate is up to date, no need for renewal ($days_exp days left)."
    exit 0;
else
    echo "The certificate for $domain is about to expire soon. Starting Let's Encrypt (HAProxy) renewal script..."
    certbot certonly --agree-tos --config /root/cli.ini

    echo "Creating $combined_file with latest certs..."
    sudo bash -c "cat /etc/letsencrypt/live/$domain/fullchain.pem /etc/letsencrypt/live/$domain/privkey.pem > $combined_file"
    chmod 640 "$combined_file"

    echo "Reloading $web_service"
    /usr/sbin/service $web_service reload
    echo "Renewal process finished for domain $domain"
    exit 0;
fi
