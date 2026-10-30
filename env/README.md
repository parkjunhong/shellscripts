# 🌐 Environment & Package Provisioning (`env/`)

리눅스 서버(Ubuntu 24+, Rocky Linux 9+, RHEL 9+, CentOS Stream 9+)의 초기 운영/개발 환경 구축, 패키지 설치, Sudoers 권한 구성, 커스텀 CLI 도구 배포, 그리고 SSH 공개키 등록을 리눅스 패키지 매니저(`dnf`, `apt`) 방식으로 일괄 제어하는 카테고리입니다.

핵심 CLI 도구인 [**`sciectl`**](sciectl/README.md)(Script, Command, Installer & Environment Controller)과 선언형 카탈로그 매니페스트(`catalogs/*.catalog`), 소프트웨어 인스톨러(`installers/*.sh`), 사후 구성 명령어(`commands/*.sh`), SSH 공개키(`keys/*.pub`)로 구성되어 있습니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | Canonical 경로 | 주요 기능 및 특징 | Bash 자동완성 | 개별 문서 |
| :--- | :--- | :--- | :---: | :---: |
| **sciectl** | [`sciectl/`](sciectl/sciectl) | 카탈로그(`@catalog`) 상속·병합, 트랜잭션 요약(`--dry-run`), OS 패키지·인스톨러·커스텀 도구·Sudoers·SSH키 일괄 프로비저닝 CLI | ✅ 지원 | [상세보기](sciectl/README.md) |

---

## 📦 제공 카탈로그 (`env/catalogs/`)

| 카탈로그 ID | 상속(`INCLUDES`) | 설명 | 주요 포함 컴포넌트 |
| :--- | :---: | :--- | :--- |
| **`default-server`** | - | 기본 서버 운영 환경 설치 | `curl`, `vim`, `jq`, `firewalld`, `scriptctl`, `vim-cli`, `sudoers-cli`, `disk-size`, `temurin-25-jdk`, `htop` |
| **`default-devops`** | `default-server` | 기본 개발/빌드/배포 환경 | `git`, `maven-3.9.15`, `build-mvn-package`, `git-*` 도구 모음, `clean-project`, `diff-file`, `install-docker-dev-config` |
| **`docker`** | - | Docker CE 및 컨테이너 관리 도구 | `docker/install-docker`, `setup-compose-service`, `setup-docker-compose`, `dknetcli`, `dkcontls` |
| **`network`** | - | 방화벽 및 네트워크 관리 도구 | `fwc-cli`, `fwc-docker-policy`, `add-vlan-routes`, `mtr-netstat-conns`, `firewall-cmd-set-priority` |
| **`gitlab`** | - | GitLab 그룹/프로젝트 일괄 Clone | `gitlab-clone`, `clone-gitlab-projects` |
| **`ai-agent`** | - | AI Agent Skill & Rule 관리 | `acs-cli` 및 기본 서버 패키지/Sudoers |
| **`install-lets-encrypt-certificate`** | - | Let's Encrypt 인증서 배포 지원 | `letsencrypt` SSH RSA 공개키 등록 |

---

## 📂 디렉토리 구조

```text
env/
├── README.md                                               # 환경 프로비저닝 카테고리 종합 안내 (본 문서)
├── sciectl/
│   ├── sciectl                                             # 통합 환경 및 패키지 프로비저닝 CLI 도구
│   ├── sciectl.completion                                  # Bash 자동완성 스크립트 (Long Option 전용)
│   └── README.md                                           # sciectl 상세 사용 설명서
├── catalogs/
│   ├── catalogs.ini                                        # 카탈로그 마스터 인덱스
│   ├── default-server.catalog                              # 기본 서버 환경 매니페스트
│   ├── default-devops.catalog                              # DevOps 빌드/배포 환경 매니페스트 (default-server 상속)
│   ├── docker.catalog                                      # Docker 엔진 및 유틸리티 매니페스트
│   ├── network.catalog                                     # 네트워크 및 방화벽 매니페스트
│   ├── gitlab.catalog                                      # GitLab Clone 환경 매니페스트
│   ├── ai-agent.catalog                                    # AI Agent (acs-cli) 매니페스트
│   └── install-lets-encrypt-certificate.catalog            # Let's Encrypt 인증서 배포용 공개키 매니페스트
├── installers/
│   ├── install-htop.sh                                     # EPEL/Universe 저장소 구성 및 htop 설치 모듈
│   ├── install-maven-3.9.15.sh                             # Apache Maven 3.9.15 바이너리(/opt) 설치 모듈
│   ├── install-temurin-25-jdk.sh                           # Adoptium Temurin 25 JDK 저장소 및 패키지 설치 모듈
│   ├── install-update-java-config.sh                       # update-java-config 설치 및 ~/.bashrc 연동 모듈
│   └── install-update-mvn-config.sh                        # update-mvn-config 설치 및 ~/.bashrc 연동 모듈
├── commands/
│   └── firewall-cmd-set-priority.sh                        # Firewalld 구동 검증 및 Zone 우선순위 설정 모듈
└── keys/
    ├── letsencrypt.pub                                     # Let's Encrypt 배포용 RSA 공개키
    └── ymtech-internal.pub                                 # 사내 표준 관리용 RSA 공개키
```

---

## 🛠️ 공통 설치 안내

### 1. 신규 서버 환경에서 원격 다운로드 및 초기 등록 절차

저장소 전체를 Clone하지 않은 신규 서버 환경에서는 아래 코드 스니펫을 복사하여 한 번에 실행하면 `scriptctl`과 `sciectl`(및 각각의 Bash 자동완성)이 시스템에 자동으로 등록됩니다.

```bash
download_dir="/tmp/sciectl-init"
mkdir -p "${download_dir}"

# 1) shellscripts/utils/scriptctl 파일 및 자동완성 다운로드
curl -sfLo "${download_dir}/scriptctl" https://raw.githubusercontent.com/parkjunhong/shellscripts/refs/heads/main/utils/scriptctl/scriptctl
curl -sfLo "${download_dir}/scriptctl.completion" https://raw.githubusercontent.com/parkjunhong/shellscripts/refs/heads/main/utils/scriptctl/scriptctl.completion
chmod +x "${download_dir}/scriptctl"

# 2) 다운로드 받은 scriptctl 파일이 자신을 시스템에 등록
"${download_dir}/scriptctl" install --script "${download_dir}/scriptctl" --force

# 3) shellscripts/env/sciectl/sciectl 파일 및 자동완성 다운로드
curl -sfLo "${download_dir}/sciectl" https://raw.githubusercontent.com/parkjunhong/shellscripts/refs/heads/main/env/sciectl/sciectl
curl -sfLo "${download_dir}/sciectl.completion" https://raw.githubusercontent.com/parkjunhong/shellscripts/refs/heads/main/env/sciectl/sciectl.completion
chmod +x "${download_dir}/sciectl"

# 4) 다운로드한 sciectl 파일을 시스템에 등록 및 임시 디렉토리 정리
"$HOME/bin/scriptctl" install --script "${download_dir}/sciectl" --force
rm -rf "${download_dir}"
```

설치가 완료된 이후에는 아래와 같이 `sciectl` 명령어를 이용하여 목적별 카탈로그 또는 개별 도구를 설치할 수 있습니다.

```bash
# 대화형 카탈로그 선택 및 설치
sciectl

# 또는 특정 카탈로그 지정 일괄 설치
sciectl install --catalog default-server,docker
```

---

### 2. 로컬 저장소(`shellscripts`) Clone 환경에서의 설치

저장소가 이미 로컬에 Clone되어 있는 경우, `utils/scriptctl` 유틸리티를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로(`/usr/local/bin`)에 간편하게 설치할 수 있습니다. 설치 시 연관된 Bash 자동완성 규칙이 시스템 표준 경로(`/usr/share/bash-completion/completions/`)에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../utils/scriptctl/scriptctl install --script ./sciectl/sciectl --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
# ※ 주의: scriptctl 자체의 권한 상승 차단을 위해 명령어 앞에 sudo를 붙이지 않습니다.
../utils/scriptctl/scriptctl install --script ./sciectl/sciectl --target global
```
