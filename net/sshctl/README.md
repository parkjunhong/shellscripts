# 🔑 sshctl

OpenSSH 기반의 다중 서버 접속 정보(호스트, 포트, 계정, 비밀번호/키 인증, 그룹)를 암호화하여 안전하게 저장하고, 대화형(Interactive) 검색 및 번호 선택으로 즉시 SSH 접속을 수행할 수 있도록 지원하는 고성능 SSH 연결 라이프사이클 관리 CLI 도구입니다.

---

## ✨ 주요 특징

1. **강력한 보안 및 암호화 관리**
   * 사용자 계정명 및 비밀번호(Credential) 등 민감 정보를 OpenSSH 개인키(`masterkey.pem`) 기반으로 비대칭 암호화하여 저장합니다.
   * 화면 출력 시 credential 값은 기본적으로 마스킹(`****************`) 처리되며, 명시적 옵션(`-s`, `--show-credential`) 지정 시에만 평문으로 조회됩니다.
2. **풍부한 검색 표현식(Search Expression) 지원**
   * `{키워드}`, `%포함%`, `접두사%`, `%접미사` 패턴 매칭 및 `and`, `or` 논리 연산자를 결합하여 대규모 인프라 환경에서도 원하는 서버를 정밀하게 필터링할 수 있습니다.
3. **대화형 연결 및 원클릭 번호 바로 접속 (`-n`, `--number`)**
   * 검색 결과 목록에서 번호(#)를 선택하여 대화형으로 접속하거나, `-n <N>` 옵션을 결합하여 목록 확인 없이 즉시 해당 서버로 접속합니다.
4. **연결 정보 라이프사이클 관리**
   * 대화형 신규 등록(`-a`), 수정(`-m`), 확인 프롬프트 기반 삭제(`-d`), 그룹 이동(`-mg`), 다중 비밀번호 일괄 갱신(`-mc`)을 모두 지원합니다.
5. **지능형 Bash 자동 완성 (`sshctl.completion`)**
   * 옵션 자동 완성뿐만 아니라 저장된 SSH 연결 이름 및 그룹 이름을 커맨드 라인에서 즉시 자동 완성 제안합니다.
6. **보조 유틸리티 제공 (`update-after-git-pull.sh`)**
   * 저장소 최신화(`git pull`) 이후 설정 파일 복사 및 환경 동기화를 지원하는 보조 스크립트가 함께 제공됩니다.

---

## ⚙️ 파라미터 명세

### 1. 기본 실행 형태
```bash
sshctl [Global Options] [커맨드/표현식]
```

### 2. 전역 옵션 (Global Options)
| 옵션 | 기본값 | 설명 |
| :--- | :---: | :--- |
| `--config <file>` | `~/.sshctl/configuration` | sshctl 설정 파일 경로 |
| `--masterkey <file>` | `~/.sshctl/masterkey.pem` | 민감정보 암/복호화에 사용할 OpenSSH Private Key 경로 |
| `-s`, `--show-credential` | 비활성 (마스킹) | 목록 및 미리보기 화면에서 비밀번호/인증값을 평문으로 출력 |
| `-n`, `--number <N>` | - | 필터링된 결과 중 N번째 항목으로 즉시 바로 접속 |

### 3. 주요 커맨드 (Commands)
| 커맨드 | 설명 |
| :--- | :--- |
| *(생략)* | 전체 connection 목록 출력 후 번호 선택 대화형 접속 |
| `<expr>` | 검색식 `<expr>`로 필터링된 목록 출력 후 대화형 접속 |
| `-l`, `--list-all [expr]` | SSH connection 목록 조회 (접속하지 않음) |
| `-a`, `--add-connection` | 새로운 SSH connection 대화형 신규 등록 |
| `-m`, `--modify-connection [expr]` | 대상 connection 선택 후 속성 수정 |
| `-d`, `--delete-connection [expr]` | 대상 connection 선택 및 사용자 확인 후 삭제 |
| `-mg`, `--move-group [expr]` | 대상 connection의 소속 그룹(Group) 일괄 변경 |
| `-mc`, `--modify-credential [expr]` | 여러 connection의 패스워드 일괄 변경 |

---

## 🚀 사용 예시

```bash
# 1) 전체 서버 목록 조회 및 대화형 선택 접속
sshctl

# 2) 'web' 키워드가 포함된 서버 목록 필터링 후 접속
sshctl web

# 3) 'prod' 그룹 중 1번째 서버로 즉시 바로 접속
sshctl "{prod}" -n 1

# 4) 복합 검색식으로 목록 조회 (개발망 또는 스테이징의 nginx 서버)
sshctl -l "{dev} or {stage} and %nginx%"

# 5) 신규 SSH 연결 정보 대화형 등록
sshctl -a

# 6) 특정 서버 정보 수정
sshctl -m "api-server"

# 7) 자격증명 평문 확인과 함께 목록 조회
sshctl -l -s
```

---

## 🧩 보조 도구 (`update-after-git-pull.sh`)

`net/sshctl/update-after-git-pull.sh`는 git 저장소에서 최신 변경사항을 당겨온(`git pull`) 뒤, 개인 설정 파일 동기화 작업을 자동화하는 보조 스크립트입니다:

```bash
./update-after-git-pull.sh --git-dir <git경로> --src-dir <원본경로> --tgt-dir <대상경로>
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./sshctl --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./sshctl --target global
```

