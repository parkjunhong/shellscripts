# 🚀 env/installers (소프트웨어 인스톨러)

`env/installers/` 디렉토리는 시스템 기본 패키지 매니저의 범위를 넘어 컴파일 설치, 공식 벤더사 바이너리 배포, 혹은 환경 변수 동적 전환 래퍼가 필요한 주요 소프트웨어들의 독립 설치 모듈들을 제공합니다.

모든 인스톨러는 표준 Canonical 디렉토리 구조(`install-<name>/install-<name>`)를 준수하며, `sciectl` 프로비저닝 엔진 또는 독립 실행을 통해 구동할 수 있습니다.

---

## 📦 제공되는 인스톨러 목록

| 인스톨러 식별자 | Canonical 디렉토리 | 설명 | 지원 OS |
| :--- | :--- | :--- | :--- |
| `htop` | [`install-htop`](./install-htop/) | 프로세스 및 리소스 모니터링 유틸리티(htop) 설치 (EPEL/APT/Homebrew) | Ubuntu, RHEL/Rocky, macOS |
| `temurin-25-jdk` | [`install-temurin-25-jdk`](./install-temurin-25-jdk/) | Eclipse Temurin 25 JDK 공식 패키지 자동 설치 | Ubuntu, RHEL/Rocky, macOS |
| `maven-3.9.15` | [`install-maven-3.9.15`](./install-maven-3.9.15/) | Apache Maven 3.9.15 바이너리 배포판 다운로드 및 `/opt` 설치 | Linux 전용 |
| `update-java-config` | [`install-update-java-config`](./install-update-java-config/) | 다중 Java 버전 전환 도구(`update-java-config`) 설치 및 쉘 자동 동기화 구성 | Ubuntu, RHEL/Rocky, macOS |
| `update-mvn-config` | [`install-update-mvn-config`](./install-update-mvn-config/) | 다중 Maven 버전 전환 도구(`update-mvn-config`) 설치 및 쉘 자동 동기화 구성 | Ubuntu, RHEL/Rocky, macOS |

---

## ⚙️ 실행 및 연동 가이드

### 1. `sciectl` 통합 실행 (권장)
`sciectl` 트랜잭션 파이프라인의 **Step 5 (소프트웨어 인스톨러)** 단계에서 카탈로그 정의 또는 개별 옵션으로 자동 실행됩니다.

```bash
# 카탈로그를 통한 일괄 설치
sciectl install --catalog default-server

# 특정 인스톨러만 단독 실행
sciectl install --installer temurin-25-jdk,htop
```

### 2. 단독 직접 실행
각 인스톨러 디렉토리로 이동하여 직접 스크립트를 실행할 수도 있습니다.

```bash
./install-htop/install-htop
./install-temurin-25-jdk/install-temurin-25-jdk
```
