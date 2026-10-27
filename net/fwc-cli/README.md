# 🛡️ fwc-cli

Linux 시스템의 방화벽 관리 도구인 `firewall-cmd`의 복잡한 Zone 규칙 조회 및 설정 작업을 직관적이고 일관된 옵션으로 래핑(Wrapping)하여 제어할 수 있도록 지원하는 **firewalld Zone 관리 전용 CLI 도구**입니다.

---

## ✨ 주요 특징

1. **직관적인 Zone 규칙 제어 인터페이스**
   * 방화벽 Zone별 정보 조회, 규칙 추가(`--add-*`), 규칙 삭제(`--remove-*`), 일괄 초기화(`--clear-all`) 작업을 단일 명령어로 손쉽게 수행합니다.
2. **풍부한 네트워크 보안 항목 지원**
   * `sources`, `services`, `ports`, `protocols`, `forward-ports`, `source-ports`, `icmp-blocks`, `rich-rules`, `interfaces` 등 firewalld의 모든 핵심 보안 요소를 포괄적으로 지원합니다.
3. **활성 존(Active Zone) 탐색 및 다중 존 지원**
   * `--active-zone` 플래그를 통해 현재 시스템에서 패킷을 처리 중인 모든 활성 Zone을 한눈에 조회하거나, 특정 Zone들의 활성 상태를 검증할 수 있습니다.
4. **원클릭 전체 규칙 일괄 초기화 (`--clear-all`)**
   * 지정된 Zone 내에 등록된 모든 규칙들을 안전하게 한 번에 초기화하여 신규 보안 템플릿 적용을 간소화합니다.
5. **영구 반영(`--permanent`) 및 즉시 리로드(`--reload`)**
   * 런타임 적용뿐만 아니라 재부팅 시에도 유지되는 영구 설정 및 변경 후 즉시 리로드 조회를 유기적으로 연결합니다.
6. **지능형 Bash 자동 완성 (`fwc-cli.completion`)**
   * 시스템에 등록된 Zone 이름 및 지원 항목에 대한 강력한 동적 자동 완성을 제공합니다.

---

## ⚙️ 파라미터 명세

```bash
fwc-cli [옵션]
```

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--zone=<zone>` | 선택 | 정보를 조회하거나 수정할 대상 Zone 이름 (중복 지정 가능) |
| `--active-zone` | 선택 | 현재 시스템에 활성화된 모든 Zone의 상세 정보 조회 |
| `--active-zone=<z1>[,<z2>]` | 선택 | 지정한 Zone들의 활성화 상태 확인 및 상세 정보 조회 |
| `--reload` | 선택 | 방화벽 설정을 리로드(`firewall-cmd --reload`)하고 활성 Zone 정보 출력 |
| `--permanent` | 선택 | 추가/삭제 작업을 영구 설정(`--permanent`)으로 반영 |
| `--clear-all` | 선택 | 대상 Zone에 등록된 모든 규칙 항목을 일괄 삭제 (가장 먼저 수행) |
| `--add-<항목>=<값>` | 선택 | 지정된 Zone에 규칙 추가 (콤마(`,`) 구분 다중 값 지원) |
| `--remove-<항목>[=<값>]` | 선택 | 지정된 Zone에서 규칙 삭제 (값 생략 시 해당 항목의 모든 규칙 일괄 삭제) |
| `-h`, `--help` | 선택 | 도움말 메시지 출력 및 종료 |

> **지원 항목 목록**: `sources`, `services`, `ports`, `protocols`, `forward-ports`, `source-ports`, `icmp-blocks`, `rich-rules`, `interfaces`

---

## 🚀 사용 예시

```bash
# 1) 현재 활성화된 모든 Zone 정보 조회
fwc-cli --active-zone

# 2) 특정 Zone(public)의 현재 설정 상태 조회
fwc-cli --zone=public

# 3) 특정 Zone에 포트(8080/tcp, 8443/tcp) 영구 추가
sudo fwc-cli --zone=public --add-ports=8080/tcp,8443/tcp --permanent

# 4) 허용 IP 대역(sources) 추가
sudo fwc-cli --zone=trusted --add-sources=192.168.1.0/24,10.10.0.0/16 --permanent

# 5) 등록된 특정 서비스(http) 삭제
sudo fwc-cli --zone=public --remove-services=http --permanent

# 6) 방화벽 설정 리로드 및 활성 상태 재확인
sudo fwc-cli --reload

# 7) 특정 Zone의 모든 규칙을 초기화하고 신규 서비스만 재등록
sudo fwc-cli --zone=custom-zone --clear-all --add-services=ssh,https --permanent
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./fwc-cli --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./fwc-cli --target global
```

