# 🐳 install-docker

리눅스 배포판 및 패키지 관리 도구(`apt`, `dnf`, `yum`)를 자동 감지하여 **Docker CE 엔진 및 핵심 플러그인(`containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`)**을 설치하고 서비스 활성화 및 사용자 그룹(`docker`) 권한 구성을 수행하는 스크립트입니다.

---

## ✨ 주요 특징

1. **다중 리눅스 배포판 및 패키지 관리자 자동 감지**
   * `/etc/os-release` 메타데이터를 분석하여 Ubuntu, Debian, RHEL, Rocky Linux, Oracle Linux, CentOS, Fedora 환경을 식별하고 최적의 패키지 관리자(`apt`, `dnf`, `yum`)를 자동으로 선택합니다.
   * 필요 시 `--pkg-mgr` 옵션으로 패키지 관리자를 명시적으로 지정할 수 있습니다.
2. **타사 저장소(PPA) 장애 격리 및 APT 잠금(Lock) 대기**
   * APT 환경에서 기존에 등록된 외부 PPA의 404/GPG 오류가 발생하더라도 전체 설치가 중단되지 않도록 복원력 있는 업데이트(`resilient_apt_update`)를 수행합니다.
   * Docker 공식 GPG 키 및 `/etc/apt/sources.list.d/docker.list` 등록 후에는 Docker 저장소만 단독으로 갱신(`isolated_docker_apt_update`)하여 외부 저장소 오류와 완전히 격리합니다.
   * 다른 프로세스가 `/var/lib/dpkg/lock-frontend` 등을 점유 중일 때 자동으로 해제될 때까지 대기합니다.
3. **서비스 자동 활성화 및 비-루트 사용자 권한(`docker` 그룹) 설정**
   * 설치 완료 후 `systemctl enable --now docker`를 통해 데몬을 즉시 기동하고 부팅 시 자동 시작되도록 등록합니다.
   * 실행 사용자(`$SUDO_USER` 또는 현재 계정)를 `docker` 그룹에 자동 추가하여 `sudo` 없이 Docker를 사용할 수 있도록 구성합니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--pkg-mgr <apt\|dnf\|yum>` | 선택 | 사용할 패키지 관리 도구를 수동으로 강제 지정 (생략 시 OS 환경에 맞춰 자동 감지) |
| `--help` | 선택 | 도움말을 출력하고 종료합니다. |

---

## 🚀 사용 예시

```bash
# 1) 현재 OS 환경을 자동 감지하여 Docker CE 및 Compose 플러그인 일괄 설치
./install-docker

# 2) 패키지 관리 도구를 DNF로 명시하여 설치
./install-docker --pkg-mgr dnf
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./install-docker --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./install-docker --target global
```

