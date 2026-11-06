# 🌐 dknetcli

Docker 브릿지(Bridge) 네트워크의 **생성(`create`)**, **삭제(`remove`)**, **상세 조회(`inspect`)**를 수행하며, 커널 브릿지 인터페이스 바인딩 검증과 서브넷 대역 충돌(Overlap) 사전 진단 기능을 제공하는 CLI 유틸리티입니다.

---

## ✨ 주요 특징

1. **서브커맨드 기반 직관적 인터페이스 (Short Option 배제)**
   * `dknetcli network <create|remove|inspect> [옵션]` 구조를 따르며, 모든 옵션은 정규 롱 옵션(Full Option)만 허용합니다.
2. **네트워크 생성 전 5단계 사전 충돌 검증 (Pre-flight Validation)**
   * **네트워크 이름 중복 검사**: 동일한 이름의 Docker 네트워크 존재 여부 확인
   * **커널 인터페이스 중복 검사**: 호스트 커널(`ip link`)에 동일한 브릿지 인터페이스명(`IFNAMSIZ`, 최대 15자) 존재 여부 확인
   * **Docker 브릿지 옵션 중복 검사**: 다른 Docker 네트워크가 `com.docker.network.bridge.name`으로 이미 점유 중인지 확인
   * **호스트 IP 충돌 검사**: 지정한 게이트웨이 IP가 호스트 물리/가상 인터페이스에 이미 할당되어 있는지 확인
   * **서브넷 CIDR 대역 중첩(Overlap) 검사**: 32비트 비트마스킹 연산을 통해 기존 Docker 네트워크 서브넷과의 대역 겹침 여부 및 게이트웨이의 서브넷 포함 여부를 정밀 검증
3. **와일드카드(`%`) 패턴 기반 네트워크 및 컨테이너 상세 조회 (`inspect`)**
   * `--name` 옵션에 `<word>`(정확히 일치), `<word>%`(접두사), `%<word>`(접미사), `%<word>%`(포함) 패턴을 지정하여 브릿지 네트워크를 검색할 수 있습니다.
   * `--containers` 옵션 추가 시 해당 네트워크에 연결된 컨테이너들의 이름, ID, IPv4 주소, MAC 주소를 함께 출력합니다.
4. **안전한 네트워크 삭제 (`remove`) 및 커널 인터페이스 해제 검증**
   * 시스템 기본 네트워크(`bridge`, `host`, `none`) 및 활성/정지 컨테이너가 연결된 네트워크의 삭제를 차단하여 사고를 예방합니다.
   * 삭제 후 호스트 커널에서 브릿지 인터페이스가 정상적으로 해제되었는지 확인합니다.
5. **단계별 대화형(Step-by-Step) 입력 모드 지원**
   * 옵션을 생략하고 `dknetcli network <create|remove|inspect>`만 실행할 경우, 대화형 프롬프트를 통해 단계별로 필요한 정보를 안내받아 손쉽게 입력할 수 있습니다.
   * `remove` 및 `inspect`에서는 현재 시스템의 Docker 브릿지 네트워크 목록이 번호 목록으로 제공되어 콤마(`,`)를 이용해 여러 대상을 손쉽게 선택할 수 있습니다.
   * `create` 및 `remove` 단계에서 사전 검증(`y`)을 선택하여 `--dry-run` 결과를 확인한 후에도, 동일한 입력 반복 없이 즉시 실제 생성 또는 삭제 작업을 이어서 진행할 수 있습니다.

---

## ⚙️ 서브커맨드 및 파라미터 명세

### 1. 서브커맨드

| 서브커맨드 | 설명 |
| :--- | :--- |
| `network create` | 커스텀 브릿지 인터페이스 및 IPAM(서브넷/게이트웨이) 설정을 적용하여 Docker 브릿지 네트워크 생성 |
| `network remove` | 지정한 Docker 브릿지 네트워크 삭제 및 커널 인터페이스 해제 확인 |
| `network inspect` | 전체 또는 조건에 일치하는 Docker 브릿지 네트워크 및 연결 컨테이너 정보 조회 |

### 2. 옵션 상세

| 옵션 | 대상 서브커맨드 | 필수 여부 | 설명 |
| :--- | :---: | :---: | :--- |
| `--name <name\|pattern>` | `create`, `remove`, `inspect` | `create`/`remove` 시 필수 | 대상 Docker 네트워크 이름 (`remove`, `inspect` 시 여러 번 지정 가능, `inspect` 시 `<word>%`, `%<word>`, `%<word>%` 패턴 지원) |
| `--bridge <bridge-name>` | `create` | **필수** | 호스트 커널에 바인딩할 브릿지 인터페이스 이름 (최대 15자, 영문/숫자/`-`/`_`/`.`) |
| `--gateway <ipv4>` | `create` | **필수** | 네트워크 게이트웨이 IPv4 주소 (예: `172.31.255.1`) |
| `--subnet <cidr>` | `create` | **필수** | CIDR 포맷의 서브넷 대역 (예: `172.31.255.0/24`, prefix `1~30`) |
| `--containers` | `inspect` | 선택 | 네트워크에 연결된 컨테이너 목록 및 IPv4/MAC 주소 상세 출력 |
| `--dry-run` | `create`, `remove` | 선택 | 실제 작업을 수행하지 않고 사전 충돌 검증 및 실행 예정 명령 시뮬레이션 출력 |
| `--help` | 공통 | 선택 | 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1) 새로운 Docker 브릿지 네트워크 생성 (시뮬레이션 모드)
./dknetcli network create \
  --name app-backend-net \
  --bridge br-app-back \
  --gateway 172.31.250.1 \
  --subnet 172.31.250.0/24 \
  --dry-run

# 2) 새로운 Docker 브릿지 네트워크 실제 생성
./dknetcli network create \
  --name app-backend-net \
  --bridge br-app-back \
  --gateway 172.31.250.1 \
  --subnet 172.31.250.0/24

# 3) 전체 브릿지 네트워크 및 연결된 컨테이너 상세 조회
./dknetcli network inspect --containers

# 4) 복수 네트워크 및 패턴 필터링 조회 (다중 --name 지정)
./dknetcli network inspect --name %app% --name test-net --containers

# 5) 복수 Docker 브릿지 네트워크 일괄 삭제 시뮬레이션
./dknetcli network remove --name app-backend-net --name test-net --dry-run

# 6) 복수 Docker 브릿지 네트워크 일괄 실제 삭제
./dknetcli network remove --name app-backend-net --name test-net

# 7) 단계별 대화형(Step-by-Step) 입력 모드 실행
./dknetcli network create   # 5단계 정보 대화형 입력 후 생성 또는 검증
./dknetcli network remove   # 번호 목록 기반 선택(콤마 구분 다중 선택 지원) 및 삭제
./dknetcli network inspect  # 번호 목록 기반 선택 및 컨테이너 포함 여부 질의 후 조회
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./dknetcli --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./dknetcli --target global
```

