# 🌐 Net (Network & Security Management Scripts)

시스템 네트워크 설정, 방화벽(firewalld), SSH 터널링 및 다중 호스트 관리, 소켓 연결 모니터링을 지원하는 통합 네트워크 유틸리티 스크립트 모음입니다.

---

## 📂 도구 목록 및 디렉토리 구조

모든 도구는 표준 **Canonical Directory** 구조로 배치되어 있으며, 각 디렉토리 내에 독립 실행 스크립트, Bash 자동 완성(`.completion`), 상세 `README.md`를 포함합니다.

| 도구 이름 (Canonical Name) | 주요 역할 및 설명 | 바로가기 |
| :--- | :--- | :---: |
| **`ssh-proxy`** | 바스천(Jump) 프록시 경유 SSH 접속 및 목적지 서비스 별칭 관리 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/net/ssh-proxy/README.md) |
| **`sshctl`** | OpenSSH 접속 자격증명 암호화 관리, 표현식 검색 및 대화형 연결 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/net/sshctl/README.md) |
| **`add-vlan-routes`** | Linux 및 macOS 환경에서 물리 인터페이스 자동 감지 기반 영구 VLAN 정적 라우팅 제어 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/net/add-vlan-routes/README.md) |
| **`ps-port`** | 프로세스 커맨드라인 패턴 매칭 기반 리슨 및 활성 네트워크 포트 추적 (JSON 지원) | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/net/ps-port/README.md) |
| **`fwc-docker-policy`** | 외부 유입 트래픽을 Docker 컨테이너로 연결하는 firewalld Policy 자동 생성 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/net/fwc-docker-policy/README.md) |
| **`fwc-cli`** | firewalld Zone별 규칙(IP, 포트, 서비스, 리치룰 등) 조회·추가·삭제·초기화 CLI 래퍼 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/net/fwc-cli/README.md) |
| **`mtr-netstat-conns`** | netstat 연결 상태 모니터링 및 다중 파이프라인 필터링·정렬 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/net/mtr-netstat-conns/README.md) |

---

## 🛠️ 공통 설치 안내

각 도구는 독립 실행형 CLI 도구로, 개인 실행 경로(`~/bin` 또는 `~/.local/bin`) 또는 전역 경로(`/usr/local/bin`)에 설치하여 바로 사용할 수 있습니다.

### `scriptctl` 도구를 사용한 간편 설치
저장소의 `utils/scriptctl` 유틸리티를 사용하면 스크립트와 Bash 자동 완성을 시스템에 한 번에 설치할 수 있습니다:

```bash
# 예: ssh-proxy 설치 (개인 환경: ~/bin)
../../utils/scriptctl/scriptctl install --script ./ssh-proxy/ssh-proxy --target local

# 예: ps-port 설치
../../utils/scriptctl/scriptctl install --script ./ps-port/ps-port --target local
```
