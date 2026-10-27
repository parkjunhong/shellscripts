# 🐳 fwc-docker-policy

외부(지정된 하나 이상의 firewalld Ingress Zone)에서 호스트로 유입되는 네트워크 요청을 Docker 브릿지 네트워크 내부의 대상 컨테이너로 포트 포워딩(DNAT)하는 **firewalld Policy**를 자동 생성 및 영구 적용하는 방화벽 정책 자동화 CLI 도구입니다.

---

## ✨ 주요 특징

1. **최신 firewalld Policy 아키텍처 완벽 지원**
   * firewalld 0.9.0+ 이상에서 도입된 Policy 오브젝트를 기반으로 Ingress Zone과 Egress Zone 간의 라우팅 및 포트 포워딩을 일관되게 구성합니다.
2. **버전별 Egress Zone 자동 감지**
   * 시스템의 `firewall-cmd` 버전을 자동 분석하여 2.3.2 이상 공식 릴리즈 환경에서는 `HOST`, 그 외 버전에서는 `ANY`를 Egress Zone으로 최적 자동 선택합니다.
3. **유연한 포트 매핑 (개별 매핑 vs 1:1 매핑)**
   * 호스트 포트와 컨테이너 포트가 상이한 경우(`--host-port`, `--cont-port`)와 동일한 경우(`--port`)를 상호 배타적 검증을 거쳐 명확하게 분기 처리합니다.
4. **다중 Ingress Zone 지원**
   * 콤마(`,`) 구분자를 통해 복수의 Ingress Zone(예: `trusted,work`)을 단일 정책 내에 동시에 묶어 구성할 수 있습니다.
5. **원자적 롤백 및 안전 장치**
   * 정책 생성 중 유효성 검증 실패 또는 런타임 오류 발생 시 생성 중이던 불완전한 정책을 자동으로 안전하게 롤백(제거)합니다.
6. **지능형 Bash 자동 완성 (`fwc-docker-policy.completion`)**
   * 시스템에 현재 구성된 firewalld Zone 목록과 정책 옵션을 동적으로 스캔하여 자동 완성을 지원합니다.

---

## ⚙️ 파라미터 명세

```bash
# 개별 포트 지정 방식
fwc-docker-policy --policy <정책명> --zone <존1[,존2,...]> --host-port <호스트포트> --cont-ip <컨테이너IP> --cont-port <컨테이너포트>

# 동일 포트 지정 방식
fwc-docker-policy --policy <정책명> --zone <존1[,존2,...]> --port <공통포트> --cont-ip <컨테이너IP>
```

| 파라미터 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--policy <name>` | **필수** | 생성할 firewalld Policy 이름 (예: `workToMariaDB`) |
| `--zone <zone1[,zone2...]>` | **필수** | 패킷을 수신할 Ingress Zone 이름 (콤마 구분 다중 지정 지원) |
| `--cont-ip <ipv4>` | **필수** | 컨테이너 내부 Unicast IPv4 주소 (예: `172.30.10.2`) |
| `--host-port <port>` | 조건부 필수 | 호스트 수신 포트 번호 (1 ~ 65535, `--port`와 동시 사용 불가) |
| `--cont-port <port>` | 조건부 필수 | 컨테이너 내부 수신 포트 번호 (1 ~ 65535, `--port`와 동시 사용 불가) |
| `--port <port>` | 조건부 필수 | 호스트와 컨테이너 포트가 동일할 때 지정 (1 ~ 65535, 개별 포트 옵션과 동시 사용 불가) |
| `--help` | 선택 | 도움말 메시지 출력 및 종료 |

---

## 🚀 사용 예시

```bash
# 1) 호스트 포트(13306)를 컨테이너 포트(3306)로 개별 매핑하여 정책 생성
sudo ./fwc-docker-policy \
  --policy workToMariaDB \
  --zone work \
  --host-port 13306 \
  --cont-ip 172.30.10.2 \
  --cont-port 3306

# 2) 호스트와 컨테이너 포트가 동일한 경우 (--port 단일 옵션)
sudo ./fwc-docker-policy \
  --policy webPublicAccess \
  --zone public \
  --port 8080 \
  --cont-ip 172.30.10.5

# 3) 복수의 수신 존(trusted, work)에 동시에 적용되는 정책 생성
sudo ./fwc-docker-policy \
  --policy dbMultiZoneAccess \
  --zone trusted,work \
  --port 5432 \
  --cont-ip 172.30.10.8
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./fwc-docker-policy --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./fwc-docker-policy --target global
```

