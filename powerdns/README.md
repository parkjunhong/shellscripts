# 🌐 PowerDNS Shell Scripts

Docker 및 컨테이너 환경에서 운영 중인 **PowerDNS 에코시스템**(PowerDNS Authoritative Server, Recursor, dnsdist, PowerDNS-Admin, MariaDB)의 상태 모니터링, 버전 진단 및 관리를 지원하는 표준 CLI 도구 모음입니다.

모든 도구는 독립 실행형 Canonical 디렉토리 구조(`powerdns/<tool>/<tool>`), 표준 Bash 자동완성(`.completion`), Unix 매뉴얼 페이지(`man/man1/`), 그리고 상세한 개별 `README.md`를 갖추고 있습니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | Canonical 경로 | 주요 기능 및 특징 | Bash 자동완성 | 매뉴얼 (`man`) | 개별 문서 |
| :--- | :--- | :--- | :---: | :---: | :---: |
| **pdns-versions** | [`pdns-versions/`](pdns-versions/pdns-versions) | Docker 기반 PowerDNS 스택 5대 컴포넌트(Auth, Recursor, dnsdist, Admin, MariaDB)의 실행 상태 및 내부 바이너리 버전 점검 | ✅ 지원 | [pdns-versions(1)](pdns-versions/man/man1/pdns-versions.1) | [상세보기](pdns-versions/README.md) |

---

## 📂 디렉토리 구조

```text
powerdns/
├── README.md                                   # PowerDNS 도구 종합 안내 (본 문서)
└── pdns-versions/
    ├── pdns-versions                           # PowerDNS 스택 버전 및 상태 점검 CLI 도구
    ├── pdns-versions.completion                # Bash 자동완성 스크립트
    ├── README.md                               # 개별 도구 상세 설명서
    └── man/
        └── man1/
            └── pdns-versions.1                 # Unix 표준 매뉴얼 페이지 (Section 1)
```

---

## 🛠️ 공통 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트와 `man` 매뉴얼 페이지도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 1) 개인 환경 설치 (~/bin, 사용자 자동완성 및 매뉴얼 등록)
../utils/scriptctl/scriptctl install --script ./pdns-versions/pdns-versions --target local

# 2) 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/, /usr/share/man/ 등록)
../utils/scriptctl/scriptctl install --script ./pdns-versions/pdns-versions --target global
```
