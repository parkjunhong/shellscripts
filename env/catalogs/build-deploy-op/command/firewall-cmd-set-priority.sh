#!/usr/bin/env bash

sudo firewall-cmd --permanent --zone=trusted --set-priority=-10
sudo firewall-cmd --permanent --zone=work --set-priority=-7
sudo firewall-cmd --permanent --zone=internal --set-priority=-4
sudo firewall-cmd --permanent --zone=external --set-priority=-1
sudo firewall-cmd --reload

exit 0
