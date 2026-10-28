# remove-service

리눅스 시스템에서 등록된 서비스(Systemd 또는 SysVinit)를 프로세스 중지, 자동 시작 비활성화, 유닛 설정 파일 삭제, 데몬 리로드 및 실패 상태 초기화까지 완벽하게 원스톱으로 정리하는 서비스 완전 삭제 도구입니다.

---

## ✨ 주요 특징

- **원스톱 서비스 완전 삭제 라이프사이클 관리**:
  1. 서비스 실행 중지 (`systemctl stop`)
  2. 부팅 시 자동 시작 비활성화 (`systemctl disable`)
  3. 모든 경로의 유닛 파일 탐색 및 안전 삭제 (`/etc/systemd/system/`, `/lib/systemd/system/`, `/usr/lib/systemd/system/`)
  4. Systemd 데몬 설정 갱신 (`systemctl daemon-reload`)
  5. 실패/잔여 상태 초기화 (`systemctl reset-failed`)
- **SysVinit 레거시 시스템 호환**: `service` 및 `chkconfig` 기반의 구형 리눅스 환경(CentOS 6 등)도 자동 감지하여 지원합니다.
- **철저한 예외 처리**: `set -Eeuo pipefail` 및 ERR 트랩을 통해 단계별 실행 상태를 추적하고 안전을 보장합니다.
- **지능형 Bash 자동완성**: 시스템에 현재 등록된 전체 서비스 목록(`systemctl list-unit-files`)을 실시간으로 파싱하여 자동완성을 제공합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `<service-name>` | **필수** | - | 삭제할 서비스 이름 (`.service` 확장자 포함/생략 모두 지원) |
| `--help` | 선택 | - | 도움말 메시지를 표시합니다. |

---

## 🚀 사용 예시

### 1. 특정 서비스 완전 삭제
```bash
remove-service nginx
```

### 2. .service 확장자를 포함하여 삭제
```bash
remove-service my-custom-app.service
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../../utils/scriptctl/scriptctl install --script ./remove-service --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../../utils/scriptctl/scriptctl install --script ./remove-service --target global
```
