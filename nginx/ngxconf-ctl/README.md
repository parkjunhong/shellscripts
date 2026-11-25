# 🌐 ngxconf-ctl

서버에 설치된 Nginx 버전에 맞추어 가상 호스트 및 설정 파일(`*.conf`)의 옵션을 지능적으로 제어하는 CLI 도구입니다. **HTTP/2 프로토콜** 및 **TLS 프로토콜(`ssl_protocols`)** 설정에 대한 상태 조회(`status`), 활성화(`enable`), 비활성화(`disable`) 기능을 제공합니다.

---

## ✨ 주요 특징

1. **지능형 Nginx 버전 감지 및 HTTP/2 분기 처리**
   * 서버에 설치된 `nginx -v` 버전을 자동 판별하여 문법 호환성을 보장합니다.
   * **Nginx 1.25.1 이상**: 최신 권장 문법인 독립 지시어(`http2 on;`)로 처리합니다. (기존 deprecated 경고 차단)
   * **Nginx 1.25.1 미만**: 레거시 문법인 `listen ... ssl http2;` 파라미터 방식으로 안전하게 변환합니다.
2. **설정 상태 조회 (`status`) 지원**
   * `http2 status`, `ssl_protocols status` 명령으로 파일 변경 없이 현재 설정 파일(`*.conf`)에 적용된 상태(활성화, 주석 비활성화, 레거시, 미설정)를 한눈에 조회할 수 있습니다.
3. **동적 TLS 버전 기반 `ssl_protocols` 제어 (미래 버전 확장성 보장)**
   * `tls1.2`, `tls1.3` 뿐만 아니라 향후 배포될 신규 버전(`tls1.4` 등)도 별도 코드 수정 없이 패턴 정규화(`TLSv1.4`)를 통해 그대로 제어할 수 있습니다.
   * **`enable`**: 기존 `ssl_protocols` 지시어에 해당 버전을 추가하거나, 주석 해제 또는 SSL 설정(`listen ... ssl` / `ssl_certificate`) 아래에 신규 삽입합니다.
   * **`disable`**: 기존 `ssl_protocols` 지시어에서 해당 버전 토큰만 안전하게 제거합니다. 마지막 프로토콜이 제거될 경우 빈 지시어 문법 오류(`ssl_protocols ;`)를 방지하기 위해 자동으로 주석 처리합니다.
4. **무중단 운영을 위한 안전 장치 및 시뮬레이션 (`--dry-run`)**
   * 작업 대상 파일 변경 전 원본 백업 파일(`.bak`)을 자동 생성합니다 (`--no-backup`으로 생략 가능, `status` 조회 시 미생성).
   * `--dry-run` 옵션을 지원하여 실제 파일 수정 없이 변경 예정 내역(diff)을 사전에 검증할 수 있습니다.
   * 변경 완료 후 시스템에 설치된 `nginx -t`를 호출하여 설정 파일 구문 오류를 즉시 검증합니다.
5. **다중 디렉토리 지원 및 최소 권한 보안 원칙 (JIT `sudo`)**
   * `--conf-dir` 옵션을 통해 콤마(`,`)로 구분된 복수 디렉토리 내의 모든 `*.conf` 파일을 일괄 처리할 수 있습니다. (기본값: `/etc/nginx/conf.d`)
   * 외부에서 `sudo ngxconf-ctl` 형태로 전체 프로세스를 root로 직접 실행하는 것을 차단하며, 파일 쓰기 권한이 필요한 시점에만 국소적으로 `sudo`를 호출합니다.

---

## ⚙️ 파라미터 및 서브커맨드 명세

### 기본 문법
```bash
ngxconf-ctl [OPTIONS] http2 <enable|disable|status>
ngxconf-ctl [OPTIONS] ssl_protocols status
ngxconf-ctl [OPTIONS] ssl_protocols <tls버전> <enable|disable>
```

### 서브커맨드 및 액션
| 서브커맨드 | 인자 / 액션 | 설명 |
| :--- | :--- | :--- |
| **`http2`** | `status` | 대상 `*.conf` 파일들의 현재 HTTP/2 설정 상태를 조회합니다. (파일 수정 없음) |
| **`http2`** | `enable` | 대상 `*.conf` 파일들의 HTTP/2 설정을 활성화합니다. (주석 해제 또는 listen 아래 신규 삽입) |
| **`http2`** | `disable` | 대상 `*.conf` 파일들의 HTTP/2 설정을 주석 처리합니다. (설정 부재 시 안내 메시지 출력) |
| **`ssl_protocols`** | `status` | 대상 `*.conf` 파일들의 현재 `ssl_protocols` 설정 상태를 조회합니다. (파일 수정 없음) |
| **`ssl_protocols`** | `<tls버전> enable` | 지정한 TLS 버전(`tls1.2`, `tls1.3`, `tls1.4` 등)을 활성화합니다. |
| **`ssl_protocols`** | `<tls버전> disable` | 지정한 TLS 버전(`tls1.2`, `tls1.3`, `tls1.4` 등)을 비활성화합니다. |

### 옵션
| 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--conf-dir <path>` | 선택 | `/etc/nginx/conf.d` | 작업 대상 `*.conf` 파일이 위치한 디렉토리 (콤마로 다중 지정 가능) |
| `--dry-run` | 선택 | `false` | 실제 파일을 수정하지 않고 변경 예정 내역(diff) 시뮬레이션 |
| `--no-backup` | 선택 | `false` | 원본 백업 파일(`.bak`)을 생성하지 않음 |
| `--nginx-version <ver>` | 선택 | (자동 감지) | 특정 Nginx 버전을 강제로 지정하여 동작 모드 결정 (예: `1.26.0`, `1.24.0`) |
| `--help` | 선택 | - | 도움말 및 옵션 안내 출력 |

---

## 🚀 사용 예시

```bash
# 1) 현재 HTTP/2 및 ssl_protocols 설정 상태 조회
ngxconf-ctl http2 status
ngxconf-ctl ssl_protocols status

# 2) 기본 설정 디렉토리(/etc/nginx/conf.d)의 설정들에 HTTP/2 활성화
ngxconf-ctl http2 enable

# 3) 실제 수정 없이 TLSv1.3 활성화 변경 예정 내역 사전 시뮬레이션 (Dry-run)
ngxconf-ctl --dry-run ssl_protocols tls1.3 enable

# 4) TLSv1.2 비활성화 및 향후 신규 TLS 버전(예: tls1.4) 활성화
ngxconf-ctl ssl_protocols tls1.2 disable
ngxconf-ctl ssl_protocols tls1.4 enable

# 5) 다중 디렉토리 지정하여 HTTP/2 비활성화 (백업 생략)
ngxconf-ctl --conf-dir /etc/nginx/conf.d,/etc/nginx/sites-enabled --no-backup http2 disable
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트와 `man` 매뉴얼 페이지도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 및 매뉴얼 등록)
../../utils/scriptctl/scriptctl install --script ./ngxconf-ctl --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/, /usr/share/man/ 등록)
# ※ 주의: scriptctl 자체의 권한 상승 차단을 위해 명령어 앞에 sudo를 붙이지 않습니다.
../../utils/scriptctl/scriptctl install --script ./ngxconf-ctl --target global
```
