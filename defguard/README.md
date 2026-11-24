# Defguard Tools

Docker 기반 Defguard VPN 인프라의 운영 상태 점검 및 관리를 지원하는 CLI 도구 모음입니다.

## 📦 제공 도구 목록
| 도구명 | 설명 | 바로가기 |
| :--- | :--- | :--- |
| `defguard-versions` | Docker 기반 Defguard VPN 스택(Core, Gateway, Proxy, PostgreSQL) 상태 및 버전 점검 | [README](./defguard-versions/README.md) |

## 📂 디렉토리 구조
```text
.
├── README.md
└── defguard-versions/
    ├── defguard-versions
    ├── defguard-versions.completion
    ├── man/
    │   └── man1/
    │       └── defguard-versions.1
    └── README.md
```

## 🛠️ 공통 설치 안내
```bash
# 개인 환경 설치 예시
../utils/scriptctl/scriptctl install --script ./defguard-versions/defguard-versions --target local
```
