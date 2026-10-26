# ⚙️ setup-compose-service

Docker Compose 기반 애플리케이션을 **Systemd OS 서비스(`.service`)**로 등록하고, 전체 또는 개별 컨테이너 제어 및 원클릭 활성화/비활성화(`enable`/`disable`)를 제공하는 **전용 제어 스크립트(`<service>-ctl.sh`)와 Bash Completion 파일**을 자동으로 생성하는 도구입니다.

---

## ✨ 주요 특징

1. **체계적인 산출물 디렉토리 분리 (`bin/` & `system/`)**
   * `--output-dir`(미지정 시 `--docker-compose-dir`) 하위에 `bin/`과 `system/` 디렉토리를 자동 구성합니다.
   * `bin/<service>[-<version>]-ctl.sh`: 서비스 제어 스크립트 (`start`, `stop`, `restart`, `status`, `enable`, `disable`)
   * `bin/<service>[-<version>]-ctl.sh.completion`: 제어 스크립트 전용 Bash 자동완성 파일 (2번째 인자로 `docker-compose.yml` 내 정의된 개별 서비스명을 동적 추천)
   * `system/<service>[-<version>].service`: Systemd 서비스 유닛 파일
2. **원클릭 시스템 등록(`enable`) 및 해제(`disable`)**
   * 생성된 `<service>-ctl.sh enable` 실행 시:
     1. `/etc/systemd/system/`에 유닛 파일 복사, `daemon-reload` 및 `systemctl enable` 수행
     2. `$HOME/bin` 디렉토리 생성 및 `~/.bashrc`(또는 `~/.bash_profile`)에 `$PATH` 영구 등록
     3. `$HOME/bin/<service>-ctl.sh` 심볼릭 링크 생성
     4. `/usr/share/bash-completion/completions/`(또는 `/etc/bash_completion.d/`)에 자동완성 등록
   * `<service>-ctl.sh disable` 실행 시 위 4가지 등록 내역을 깔끔하게 역순으로 제거합니다.
3. **SELinux 보안 컨텍스트 및 권한 자동화**
   * RHEL / Rocky Linux 등 SELinux 활성화 환경에서 Systemd가 스크립트를 차단하지 않도록 산출물의 소유권을 `root:root`로 설정하고 `restorecon` 및 `chcon`(`bin_t`, `systemd_unit_file_t`)을 자동으로 부여합니다.
4. **사전 무결성 점검 (Pre-flight Check)**
   * 기동 전 `docker compose config`를 통해 `docker-compose.yml` 및 `.env` 파일의 문법/환경변수 누락 여부를 검증하며, 기존 Systemd 서비스와의 이름 충돌을 사전에 차단합니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--docker-compose-dir <path>` | **필수** | `docker-compose.yml` 또는 `docker-compose.yaml` 파일이 위치한 디렉토리 경로 |
| `--service <name>` | **필수** | 등록할 서비스 식별자 이름 (영문, 숫자, `-`, `_` 허용) |
| `--version <version>` | 선택 | 서비스 버전 문자열 (지정 시 `<service>-<version>` 형태로 식별자 구성) |
| `--output-dir <path>` | 선택 | `bin/` 및 `system/` 산출물 디렉토리를 생성할 기준 경로 (기본값: `--docker-compose-dir`) |
| `--help` | 선택 | 도움말을 출력하고 종료합니다. |

---

## 🚀 사용 예시

```bash
# 1) /opt/apps/keycloak 디렉토리의 Compose 프로젝트를 기반으로 제어 스크립트 및 Systemd 유닛 생성
./setup-compose-service \
  --docker-compose-dir /opt/apps/keycloak \
  --service keycloak \
  --version 26.0.0

# 2) 생성된 제어 스크립트를 통해 Systemd 서비스, $HOME/bin 심볼릭 링크, 자동완성 일괄 활성화
sudo /opt/apps/keycloak/bin/keycloak-26.0.0-ctl.sh enable

# 3) 이후 어디서나 제어 명령 및 탭(TAB) 자동완성 사용
keycloak-26.0.0-ctl.sh start
keycloak-26.0.0-ctl.sh status
```
