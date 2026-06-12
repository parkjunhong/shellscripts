#!/usr/bin/env bash

# trusted 존의 Ingress와 Egress 우선순위를 모두 -10으로 조정
sudo firewall-cmd --permanent --zone=trusted --set-priority=-10

exit 0
