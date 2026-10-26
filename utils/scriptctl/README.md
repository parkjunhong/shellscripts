# 🛠️ scriptctl

커스텀 스크립트와 연관된 Bash 자동 완성(`.completion`) 파일의 **설치(`install`)**, **삭제(`remove`)**, **현황 조회(`list`)**를 하나로 통합 관리하는 CLI 도구입니다.

---

## ✨ 주요 특징

1. **서브커맨드 기반 통합 인터페이스 (`scriptctl <command> [options]`)**
   * `scriptctl install ...` : 커스텀 스크립트 및 연관 `.completion` 파일 설치
   * `scriptctl remove ...` : 설치된 커스텀 스크립트 및 연관 `.completion` 파일 안전 삭제
   * `scriptctl list ...` : 개인/전역 실행 공간에 설치된 커스텀 스크립트 및 `.completion` 매핑 현황 조회
2. **개인(`local`) 및 전역(`global`) 실행 공간 완벽 지원**
   * **설치 (`install`)**:
     * `--target local` (기본값): `$HOME/bin`에 설치 (미존재 시 자동 생성, 일반 파일로 존재 시 상태 출력 후 오류 종료)
     * `--target global`: `/usr/local/bin`에 설치
   * **삭제 (`remove`) 및 조회 (`list`)**:
     * `--target local`: 개인 실행 공간(`$HOME/bin`, `$HOME/.local/bin`) 탐색
     * `--target global`: 전역 실행 공간(`/usr/local/bin`) 탐색
     * `--target all` (기본값): 개인·전역 실행 공간 및 `$PATH` 전체 탐색
3. **지능형 Bash 자동 완성 (`scriptctl.completion`)**
   * `scriptctl remove --name <TAB>` 입력 시 현재 작업 디렉토리가 아니라 **`$HOME/bin`, `$HOME/.local/bin`, `/usr/local/bin`에 실제 설치된 커스텀 스크립트 목록**을 동적으로 스캔하여 추천합니다.
   * 만약 `scriptctl remove --target local --name <TAB>`처럼 `--target`이 먼저 지정되어 있으면 해당 범위(`$HOME/bin`, `$HOME/.local/bin`)의 스크립트만 필터링하여 제안합니다.
4. **시스템 보호 및 최소 권한(`sudo`) 원칙**
   * 스크립트 자체를 외부에서 `sudo scriptctl ...`로 실행하는 것을 차단하며, 작업 대상 경로에 쓰기/삭제 권한이 필요한 시점에만 내부적으로 `sudo` 인증을 요청합니다.
   * OS 핵심 유틸리티 블랙리스트, ELF 바이너리, 패키지 관리자(`RPM`/`DPKG`) 소속 파일은 덮어쓰기 및 삭제가 원천 차단됩니다.

---

## ⚙️ 명령어 및 옵션 명세

### 1. `scriptctl install`
| 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--script <PATH>` | **필수** | - | 설치할 스크립트 파일 경로 (절대/상대 경로 지원) |
| `--target <local\|global>` | 선택 | `local` | 설치 범위 (`local`: `$HOME/bin`, `global`: `/usr/local/bin`) |
| `--force` | 선택 | `false` | 기존 파일 확인 없이 덮어쓰기 |
| `--dry-run` | 선택 | `false` | 실제 설치 없이 예정된 작업 계획과 필요 권한만 출력 |
| `--help` | 선택 | - | `install` 서브커맨드 도움말 출력 |

### 2. `scriptctl remove`
| 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--name <NAME_OR_PATTERN>` | **필수** | - | 삭제할 스크립트 파일명, 경로 또는 와일드카드 패턴 (예: `'yes-*'`, 따옴표 권장) |
| `--target <local\|global\|all>` | 선택 | `all` | 탐색 범위 (`local`: `$HOME/bin`·`$HOME/.local/bin`, `global`: `/usr/local/bin`, `all`: 전체) |
| `--force` | 선택 | `false` | 삭제 확인 프롬프트(`y/N`) 생략 |
| `--dry-run` | 선택 | `false` | 실제 삭제 없이 삭제 대상 목록과 필요 권한만 출력 |
| `--help` | 선택 | - | `remove` 서브커맨드 도움말 출력 |

### 3. `scriptctl list`
| 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--target <local\|global\|all>` | 선택 | `all` | 조회할 실행 공간 범위 지정 |
| `--help` | 선택 | - | `list` 서브커맨드 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1) 개인 실행 공간($HOME/bin)에 스크립트 설치 (기본값)
./scriptctl install --script ../../net/ps-port/ps-port

# 2) 전역 실행 공간(/usr/local/bin) 설치 시뮬레이션
./scriptctl install --script ../../net/ps-port/ps-port --target global --dry-run

# 3) 설치된 커스텀 스크립트 목록 및 completion 현황 조회
./scriptctl list

# 4) 개인 실행 공간에 설치된 스크립트 삭제
./scriptctl remove --name ps-port --target local

# 5) 와일드카드 패턴('yes-*')과 일치하는 모든 스크립트 및 연관 completion 삭제 시뮬레이션
./scriptctl remove --name 'yes-*' --target local --dry-run
```
