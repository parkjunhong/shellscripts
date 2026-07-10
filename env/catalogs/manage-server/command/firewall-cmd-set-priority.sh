#!/usr/bin/env bash

run_cmd() {
    local -a cmd=("$@")

    echo
    echo "${cmd[*]}"
    "${cmd[@]}"
}

run_cmd sudo firewall-cmd --permanent --zone=trusted  --set-priority=-10
run_cmd sudo firewall-cmd --permanent --zone=work     --set-priority=-7
run_cmd sudo firewall-cmd --permanent --zone=internal --set-priority=-4
run_cmd sudo firewall-cmd --permanent --zone=external --set-priority=-1
run_cmd sudo firewall-cmd --permanent --zone=external --set-priority=-1

run_cmd sudo firewall-cmd --reload

exit 0
