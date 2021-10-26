#!/usr/bin/env bash

email="youremail@your.domain"
root_domain="your.domain"
wc_domain="*.$root_domain"

echo "sudo certbot certonly --manual --preferred-challenges=dns --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d '$root_domain' -d '$wc_domain' --email '$email'"
sudo certbot certonly --manual --preferred-challenges=dns --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d '$root_domain' -d '$wc_domain' --email '$email'

exit 0
