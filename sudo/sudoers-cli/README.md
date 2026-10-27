# sudoers-cli

시스템 계정 또는 그룹을 대상으로 `/etc/sudoers.d/` 디렉토리 하위에 안전하고 표준화된 Sudoers 권한 정책을 생성·병합하고, `visudo` 엔진을 통해 문법 정합성을 사전 검증하여 오류 발생 시 자동 롤백하는 안전한 CLI 권한 관리 도구입니다.

---

## ✨ 주요 특징

- **계정 및 그룹 대상 정책 분리 관리**:
  - 사용자 계정(`-u, --user`): `/etc/sudoers.d/user-<계정명>`으로 격리 생성
  - 시스템 그룹(`-g, --group`): `/etc/sudoers.d/group-<그룹명>`으로 격리 생성
- **세부 정책 속성 및 Sudoers 태그 제어**:
  - 호스트(`-H, --host`, 기본값: `ALL`), RunAs(`-r, --runas`, 기본값: `ALL`), 태그 옵션(`-o, --option`, 기본값: `NONE`) 지정
  - `NOPASSWD`, `PASSWD`, `NOEXEC`, `EXEC`, `SETENV`, `NOSETENV`, `LOG_INPUT`, `NOLOG_INPUT` 등 복수 태그 옵션 지원
- **실행 명령어 검증 및 패키지 설치 연계**:
  - 명령어의 절대 경로(`command -v`, `realpath`)를 자동 해석하여 기재
  - 시스템에 존재하지 않는 명령어 입력 시 OS 패키지 관리자(`dnf`, `yum`, `apt-get`)를 감지하여 대화형 설치 지원
- **지능형 정책 병합(Merge) 및 최적화**:
  - 동일한 접두사(호스트, RunAs, 옵션)를 가진 기존 정책 라인을 찾아 신규 명령어를 안전하게 병합
  - 전역 권한인 `ALL`이 추가되거나 이미 등록된 경우, 불필요한 개별 명령어를 자동으로 흡수 및 중복 제거
- **원자적 검증 및 자동 롤백 (Atomic Validation & Rollback)**:
  - 설정 파일 생성 직후 `chmod 0440` 권한을 설정하고 `visudo -c -f` 명령어로 문법 정합성을 사전 검증
  - 문법 오류 발생 시 생성 파일을 즉시 삭제(롤백)하여 관리자 잠김(Lockout) 사고를 원천 방지
- **고급 Bash 자동완성**: 시스템 계정(`/etc/passwd`), 시스템 그룹(`/etc/group`), 태그 옵션 및 시스템 실행 명령어(`compgen -c`, `compgen -f`)를 상황에 맞게 동적으로 추천합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 단축 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :---: | :--- |
| `--user <계정명>` | `-u` | 조건부 필수 | - | 권한을 부여할 대상 시스템 계정 (계정 또는 그룹 중 택 1 필수) |
| `--group <그룹명>` | `-g` | 조건부 필수 | - | 권한을 부여할 대상 시스템 그룹 (계정 또는 그룹 중 택 1 필수) |
| `--host <호스트>` | `-H` | 선택 | `ALL` | 명령어 실행을 허용할 호스트 (예: `ALL`, `localhost`, `web-01`) |
| `--runas <사용자>` | `-r` | 선택 | `ALL` | 명령 실행 시 차용할 권한 (예: `ALL`, `root`, `tomcat:was`) |
| `--option <옵션>` | `-o` | 선택 | `NONE` | Sudoers 태그 옵션 (예: `NOPASSWD`, `NOEXEC`, `SETENV` 등 콤마 구분) |
| `[명령어1] [명령어2]...` | - | **필수** | - | 실행을 허용할 명령어 목록 (절대 경로, 바이너리명 또는 `ALL`) |
| `--help` | `-h` | 선택 | - | 도움말 메시지를 표시합니다. |

---

## 🚀 사용 예시

### 1. 특정 계정에 비밀번호 면제(`NOPASSWD`) 명령어 권한 부여
```bash
sudoers-cli -u devuser -o NOPASSWD /usr/bin/systemctl /usr/bin/cat
```

### 2. 특정 그룹에 호스트 및 복수 옵션(`NOPASSWD,NOEXEC`) 적용
```bash
sudoers-cli -g devops -H web-server-01 -o NOPASSWD,NOEXEC /usr/bin/systemctl
```

### 3. 특정 계정에 전역 관리자 권한(`ALL`) 부여
```bash
sudoers-cli -u admin ALL
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../../utils/scriptctl/scriptctl install --script ./sudoers-cli --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../../utils/scriptctl/scriptctl install --script ./sudoers-cli --target global
```
