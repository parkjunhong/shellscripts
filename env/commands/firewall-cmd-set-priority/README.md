# ⚡ firewall-cmd-set-priority

Linux 환경에서 **firewalld** 서비스의 존(Zone) 및 체인별 규칙 우선순위(Priority)를 안전하게 초기화하고 표준 정책을 적용하는 시스템 사후 구성 명령어 스크립트입니다.

---

## ✨ 주요 특징

1. **OS 및 데몬 사전 검증**:
   * macOS 등 방화벽 데몬이 존재하지 않는 환경에서는 에러를 내지 않고 안전하게 건너뜁니다.
   * `firewalld` 서비스가 미설치되어 있거나 비활성화되어 있는 경우 사전 상태를 점검합니다.
2. **네트워크 보안 정책 표준화**:
   * 네트워크 인터페이스 및 VLAN 라우팅 규칙과 Docker 브릿지 네트워크 간의 트래픽 간섭을 방지하기 위한 우선순위 정렬을 수행합니다.

---

## ⚙️ 사용법

### 1. `sciectl`을 통한 실행
```bash
sciectl install --command firewall-cmd-set-priority
```

### 2. 단독 직접 실행
```bash
sudo ./firewall-cmd-set-priority
```

---

## 📋 시스템 요구사항
* Linux 환경 (`firewalld` 패키지 설치 및 실행 권한)
* `sudo` 관리자 권한
