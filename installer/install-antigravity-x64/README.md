# 🚀 install-antigravity-x64

Google Antigravity 공식 저장소에서 사용 가능한 **Antigravity Core/CLI(2.x 이상)** 버전 목록을 원격 조회하고, 운영체제(Linux x64, macOS Apple Silicon/Intel)에 맞는 최적의 배포 패키지를 다운로드하여 시스템에 자동 설치 및 환경 구성을 수행하는 크로스 플랫폼 CLI 설치 도구입니다.

---

## ✨ 주요 특징

1. **크로스 플랫폼(Linux & macOS) 자동 감지 및 맞춤형 설치**
   * **Linux**: `tar.gz` 아카이브 다운로드, `/opt/antigravity` 설치, `app.asar` 정밀 파싱 기반 앱 아이콘 복원, XDG 데스크톱 엔트리(`antigravity.desktop`) 및 샌드박스 보안 권한(`chrome-sandbox`) 자동 구성.
   * **macOS (Apple Silicon & Intel)**: `dmg` 디스크 이미지 다운로드, `hdiutil attach` 마운트 후 `ditto`를 통한 `/Applications/Antigravity.app` 안전 복사, Gatekeeper 격리 속성 해제(`xattr -cr`), `/usr/local/bin/antigravity` 및 `/usr/local/bin/agy` CLI 심볼릭 링크 자동 생성.
2. **설치 버전 자동 감지 및 합리적 버전 목록 필터링**
   * 현재 시스템에 설치된 버전(Linux: `app.asar`, macOS: `Info.plist`/`app.asar`)을 정밀 자동 감지합니다.
   * 무조건 전체 버전을 나열하는 대신, 설치된 버전과 최신 릴리즈 사이의 합리적인 구간(기본 각 구간별 최대 5개)을 최신순으로 제공합니다.
   * 버전 목록에 `(latest)`, `(installed)`, `(latest, installed)` 라벨을 부여하여 현재 설치 상태와 최신 상태를 직관적으로 파악할 수 있습니다.
3. **누락/생략된 버전 가시화 (`...`)**
   * 상한 제한이나 구간 건너뜀으로 인해 목록에서 생략된 버전들이 존재하는 경우, 해당 위치에 `... (<N>개 버전 생략)` 형태로 누락된 버전 수와 전체 확인 방법을 명확히 안내합니다.
4. **유연한 검색 및 필터 옵션 지원 (`--version-matched`, `--unlimited`)**
   * `--version-matched`: 지정한 `--version` 값과 접두사 일치(`startsWith`)하는 특정 마이너/패치 버전군만 집중 필터링합니다.
   * `--unlimited`: 구간별 5개 목록 상한을 해제하고 조건에 부합하는 전체 버전 목록을 모두 출력합니다.
5. **구버전 정리 및 임시 파일 안전 회수 (Trap)**
   * 설치 도중 중단되거나 오류가 발생하더라도 `trap` 기반 임시 다운로드 파일 및 macOS 볼륨 마운트 자동 정리 로직이 동작하여 시스템 찌꺼기를 남기지 않습니다.
6. **시뮬레이션 모드 (`--dry-run`) 지원**
   * 실제 시스템 파일 변경 없이 다운로드 URL, 설치 경로 및 실행될 단계들을 사전 검증할 수 있습니다. (`ANTIGRAVITY_FORCE_OS`, `ANTIGRAVITY_FORCE_ARCH` 환경변수로 타 OS 시뮬레이션 가능)

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--version <버전>` | 선택 | 원격 저장소에서 검색/기준으로 사용할 버전 식별자 (예: `2`, `2.28`, `2.28.2`). 생략 시 설치 상태에 따라 합리적인 최신 버전 목록을 제공 |
| `--version-matched` | 선택 | `--version` 값과 접두사 일치(`startsWith`)하는 버전군만 필터링 (반드시 `--version`과 함께 사용) |
| `--unlimited` | 선택 | 구간별 최대 5개 목록 제한을 해제하고 조건에 부합하는 전체 버전 목록을 출력 |
| `--dry-run` | 선택 | 실제 다운로드 및 시스템 설치를 진행하지 않고 실행 계획만 출력 |
| `--help` | 선택 | 도움말 출력 및 종료 |

> **주의**: 단축 옵션(`-v`, `-d`, `-h` 등)은 지원하지 않으며 정규 롱 옵션만 지원합니다.

---

## 🚀 사용 예시

```bash
# 1) 설치 상태에 따른 최신 버전 목록 대화형 확인 및 선택 설치
./install-antigravity-x64

# 2) 특정 버전(예: 2)을 기준으로 목록 조회 (설치 버전과 연계된 구간 최대 10개)
./install-antigravity-x64 --version 2

# 3) 특정 버전 접두사와 일치하는 버전군만 필터링 (예: 2.28.*)
./install-antigravity-x64 --version 2.28 --version-matched

# 4) 5개 개수 제한 없이 전체 버전 목록 확인
./install-antigravity-x64 --unlimited
./install-antigravity-x64 --version 2 --unlimited

# 5) 실제 설치 없이 시뮬레이션 모드로 확인
./install-antigravity-x64 --dry-run
./install-antigravity-x64 --version 2.28.2 --dry-run
```

---

## 💻 설치 안내

### 1. `sciectl` 카탈로그를 통한 설치 (권장)
이 도구는 `shellscripts/env/catalogs/installer.catalog`의 `CUSTOM_TOOLS`에 포함되어 있어 `sciectl`을 통해 원클릭으로 설치할 수 있습니다:
```bash
sciectl --catalog installer
```

### 2. `scriptctl` 도구를 통한 단독 설치
저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./install-antigravity-x64 --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./install-antigravity-x64 --target global
```

