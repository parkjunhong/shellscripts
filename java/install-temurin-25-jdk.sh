#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : install eclipse temurin jdk 25.
# @license : Apache License 2.0
# @since : 2026-05-12
# @desc : support RHEL, Oracle Linux, Ubuntu, RockyOS
# @installation :
# 1. insert 'source <path>/<파일명>' into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/<파일명>' into etc/bashrc for all users.
# =======================================

FILENAME=$(basename $0)

help(){
    if [ ! -z "$1" ]; then
        local indent=10
        local formatl=" - %-"$indent"s: %s\n"
        local formatr=" - %"$indent"s: %s\n"
        echo
        echo "================================================================================"
        printf "$formatl" "filename" "$FILENAME"
        printf "$formatl" "line" "$2"
        printf "$formatl" "callstack"
        local idx=1
        for func in ${FUNCNAME[@]:1}
        do
            printf "$formatr" "["$idx"]" $func
            ((idx++))
        done
        printf "$formatl" "cause" "$1"
        echo "================================================================================"
    fi
    echo
    # TODO: Usage 내용 작성
    echo "Usage: $FILENAME [options]"
    echo "Options:"
    echo "  -h, --help    도움말을 출력하고 종료합니다."
    echo "Description:"
    echo "  Ubuntu 24.04+ 및 Rocky Linux 9+ 환경에 Eclipse Temurin JDK 25를 설치합니다."
}

##
# OS 환경을 확인하고 지원 여부를 검증합니다.
#
# @return (os_type 문자열 출력, 미지원 시 에러 메시지 출력 후 스크립트 종료)
##
check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu)
                echo "ubuntu"
                ;;
            rocky|rhel|centos|ol)
                echo "rocky"
                ;;
            *)
                help "Unsupported OS: $ID" ${LINENO}
                exit 1
                ;;
        esac
    else
        help "Cannot determine OS. /etc/os-release not found." ${LINENO}
        exit 1
    fi
}

##
# Ubuntu 환경(24.04 이상)에 맞게 저장소를 추가하고 JDK 25를 설치합니다.
#
# @return (설치 진행 상황 표준 출력)
##
install_ubuntu() {
    echo "[INFO] Ubuntu 환경에서 설치를 시작합니다..."
    sudo apt-get update -y
    sudo apt-get install -y wget apt-transport-https gnupg
    
    # Adoptium GPG 키 등록 및 리포지토리 추가
    wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/adoptium.gpg
    echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list
    
    sudo apt-get update -y
    sudo apt-get install -y temurin-25-jdk
}

##
# Rocky Linux (9 이상) 및 RHEL 계열에 맞게 저장소를 추가하고 JDK 25를 설치합니다.
#
# @return (설치 진행 상황 표준 출력)
##
install_rocky() {
    echo "[INFO] Rocky Linux 환경에서 설치를 시작합니다..."
    
    # Adoptium 리포지토리 파일 생성
    cat <<EOF | sudo tee /etc/yum.repos.d/adoptium.repo
[Adoptium]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/rhel/\$releasever/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF
    
    sudo dnf install -y temurin-25-jdk
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    help
    exit 0
fi

##
# 메인 실행 함수입니다. 시스템 검증 후 적합한 설치 함수를 호출합니다.
##
main() {
    local os_type=$(check_os)
    
    if [ "$os_type" == "ubuntu" ]; then
        install_ubuntu
    elif [ "$os_type" == "rocky" ]; then
        install_rocky
    else
        help "OS validation failed. Unsupported environment." ${LINENO}
        exit 1
    fi
    
    echo "[INFO] JDK 25 설치가 완료되었습니다. 버전을 확인합니다."
    java -version
}

main "$@"
exit 0
