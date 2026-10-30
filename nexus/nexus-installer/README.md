# nexus-installer

`nexus-installer`는 Sonatype Nexus Repository를 원격 다운로드 또는 로컬 패키지 파일을 기반으로 설치 및 서비스 등록을 수행하고, 다중 인스턴스 환경 구성 및 기존 인스턴스의 완전한 언인스톨을 지원하는 운영 관리 CLI 도구입니다.

---

## ✨ 주요 특징

- **원스톱 설치 파이프라인**:
  - 원격 다운로드 URL(`--download-url`) 또는 로컬 압축 파일(`--file`)을 통해 최신/지정 버전 자동 설치
  - 전용 실행 계정(`--user`, 기본값: `nexus`) 자동 생성 및 디렉터리 권한 부여
  - systemd 서비스 파일(`nexus-<version>.service`) 자동 생성 및 등록
  - HTTP 포트(`--port`, 기본값: `8081`) 및 데이터 디렉토리 분리 구성
- **다중 인스턴스 관리**: 하나의 시스템에 여러 버전의 Nexus 인스턴스를 격리하여 병행 운용할 수 있도록 메타데이터 인스턴스 레지스트리를 유지합니다.
- **안전한 완전 삭제 (`--uninstall`)**: 등록된 Nexus 인스턴스 목록을 대화형으로 선택하여 실행 프로세스 중단, systemd 서비스 등록 해제, 데이터 디렉터리 정리 및 계정 삭제를 단계별로 안전하게 처리합니다.
- **시뮬레이션 모드 (`--dry-run`)**: 시스템에 실제 변경을 가하지 않고 전체 설치/삭제 절차 및 명령어들을 사전에 검증할 수 있습니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 **Long Option** 전용으로 동작하며, Short Option은 지원하지 않습니다.

### 1. 작업 선택 (둘 중 하나 필수)
| 옵션 | 설명 |
| :--- | :--- |
| `--install` | Nexus 서비스 신규 설치 및 systemd 등록 |
| `--uninstall` | 기 설치된 Nexus 인스턴스 대화형 선택 및 완전 삭제 |

### 2. 공통 옵션
| 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :--- | :--- |
| `--dry-run` | 선택 | `false` | 실제 시스템 변경 없이 작업 과정 시뮬레이션 수행 |
| `--help` | 선택 | - | 도움말 및 옵션 안내 출력 |

### 3. 설치(`--install`) 전용 옵션
| 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :--- | :--- |
| `--download-url <URL>` | 조건부 필수 | - | Nexus tar.gz 패키지 다운로드 URL (`--file`과 상호 배타적) |
| `--file <파일경로>` | 조건부 필수 | - | Nexus tar.gz 패키지 로컬 파일 경로 (`--download-url`과 상호 배타적) |
| `--install-dir <경로>` | 선택 | `/opt/sonatype` | Nexus 상위 설치 디렉토리 |
| `--version <버전>` | 선택 | 자동 추출 | 설치할 Nexus 버전 명시 지정 (미지정 시 URL/파일명에서 자동 추출) |
| `--user <계정명>` | 선택 | `nexus` | Nexus 실행 전용 시스템 계정 |
| `--port <포트>` | 선택 | `8081` | Nexus 웹 서비스 HTTP 포트 번호 |

---

## 🚀 사용 예시

### 1. 원격 다운로드를 통한 설치
```bash
nexus-installer --install --download-url "https://download.sonatype.com/nexus/3/nexus-3.70.1-02-unix.tar.gz" --port 8081
```

### 2. 로컬 패키지 파일을 이용한 설치
```bash
nexus-installer --install --file /tmp/nexus-3.70.1-02-unix.tar.gz --user nexus --port 8082
```

### 3. 설치 과정 Dry-run 시뮬레이션
```bash
nexus-installer --install --file /tmp/nexus-3.70.1-02-unix.tar.gz --dry-run
```

### 4. 기존 인스턴스 언인스톨
```bash
nexus-installer --uninstall
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./nexus-installer --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./nexus-installer --target global
```
