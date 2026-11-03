# 🚀 install-albert-with-socket

openSUSE Build Service(OBS) 공식 저장소에서 **Albert 런처**를 설치하고, Wayland 환경에서 단축키를 통한 즉각적이고 안정적인 창 전환을 지원하기 위한 **IPC Socket 토글 도구**를 자동 구성하는 CLI 설치 도구입니다.

---

## ✨ 주요 특징

1. **OBS 공식 저장소 연동 및 APT 키링 자동 구성**
   * 공식 키링(`/etc/apt/keyrings/albert.gpg`) 및 APT 소스 리스트(`/etc/apt/sources.list.d/albert.list`)를 안전하게 등록합니다.
2. **Ubuntu 릴리즈 버전 자동 감지 및 맞춤형 저장소 설정**
   * `/etc/os-release`를 분석하여 시스템의 Ubuntu 버전(예: `22.04`, `24.04`, `26.04` 등)을 자동으로 감지하고 최적화된 OBS 저장소를 연결합니다.
   * 필요시 `--release` 옵션으로 대상을 직접 지정할 수 있습니다.
3. **Wayland 환경 특화 IPC Socket 토글러 자동 생성**
   * Wayland 세션에서 기존 `albert toggle` 명령의 느린 지연 시간 또는 먹통 현상을 방지하기 위해, UNIX 도메인 소켓(`~/.cache/albert/ipc_socket`)과 `socat`을 활용하는 고속 토글 스크립트(`albert-toggle`)를 자동 생성합니다.
4. **시뮬레이션 모드 (`--dry-run`) 지원**
   * 실제 시스템 패키지 설치나 파일 수정을 진행하지 않고 전체 설치 단계 및 실행 명령어를 사전에 검증할 수 있습니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--release <버전>` | 선택 | 시스템 자동 감지 | 대상 Ubuntu 릴리즈 버전 (예: `22.04`, `24.04`, `26.04`) |
| `--toggle-path <경로>` | 선택 | `~/.local/bin/albert-toggle` | IPC Socket 토글 스크립트가 생성될 경로 |
| `--skip-toggle` | 선택 | `false` | Albert 패키지만 설치하고 토글 스크립트 생성을 건너뜀 |
| `--dry-run` | 선택 | `false` | 실제 설치를 수행하지 않고 실행 계획만 출력 |
| `--help` | 선택 | - | 도움말 출력 |

> **주의**: 단축 옵션(`-r`, `-t`, `-h` 등)은 지원하지 않으며 정규 롱 옵션만 지원합니다.

---

## 🚀 사용 예시

```bash
# 1) 시스템 버전을 자동 감지하여 기본 경로(~/.local/bin/albert-toggle)로 설치
./install-albert-with-socket

# 2) 특정 Ubuntu 버전(예: 24.04)을 명시하여 설치
./install-albert-with-socket --release 24.04

# 3) 토글 스크립트 저장 경로를 사용자 지정하여 설치
./install-albert-with-socket --toggle-path ~/bin/albert-toggle

# 4) 실제 변경 없이 설치 단계 시뮬레이션
./install-albert-with-socket --dry-run
```

---

## ⌨️ GNOME 단축키 설정 가이드 (Wayland)

설치가 완료되면 다음 절차에 따라 Albert 전역 호출 단축키(`Alt + Space`)를 등록하십시오.

### 1. GNOME 기본 창 메뉴 단축키 충돌 해제
`Alt + Space`가 GNOME 기본 창 메뉴 단축키로 선점되어 있는 경우, 이를 해제해야 정상 작동합니다.

```bash
# 현재 설정 확인
gsettings get org.gnome.desktop.wm.keybindings activate-window-menu

# '<Alt>space'가 포함된 경우 할당 해제
gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "[]"
```

### 2. 사용자 정의 단축키 등록
1. **설정 (Settings)** &rarr; **키보드 (Keyboard)**
2. **바로가기 보기 및 사용자 지정 (View and Customize Shortcuts)** 클릭
3. **사용자 정의 바로가기 (Custom Shortcuts)** 선택 &rarr; **바로가기 추가 (+)**
4. 다음 정보를 입력하고 등록:
   * **이름 (Name)**: `Albert`
   * **명령 (Command)**: `~/.local/bin/albert-toggle` (또는 지정한 토글 스크립트 경로)
   * **바로가기 (Shortcut)**: `Alt + Space`

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./install-albert-with-socket --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./install-albert-with-socket --target global
```
