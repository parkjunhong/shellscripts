# wrangler

Cloudflare Workers/Pages 및 D1 데이터베이스 개발, 로컬 서버 구동, 스키마 초기화 및 마이그레이션을 지원하는 유틸리티 도구 디렉토리입니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | 설명 | 지원 기능 |
| :--- | :--- | :--- |
| [`start-wrangler`](./start-wrangler/README.md) | Cloudflare Pages 개발 서버(`wrangler pages dev`) 구동 도구 | 경로 검증, 바인딩 IP 파라미터화(`--ip`), 로컬 HTTPS 개발 환경 연동 |
| [`init-wrangler-d1`](./init-wrangler-d1/README.md) | Cloudflare D1 데이터베이스 스키마 초기화 및 데이터 백업 도구 | 로컬/원격/전체 D1 스키마 배포, 원격 D1 데이터 로컬 마이그레이션 백업 |
| [`migration-d1-init-scheme`](./migration-d1-init-scheme/README.md) | D1 SQL 마이그레이션용 DROP TABLE 자동 주입 전처리 도구 | CREATE TABLE 앞 DROP TABLE 구문 자동 삽입, 안전한 덮어쓰기 제어 |

---

## 📁 디렉토리 구조

```plaintext
wrangler/
├── README.md
├── init-wrangler-d1/
│   ├── README.md
│   ├── init-wrangler-d1
│   └── init-wrangler-d1.completion
├── migration-d1-init-scheme/
│   ├── README.md
│   ├── migration-d1-init-scheme
│   └── migration-d1-init-scheme.completion
└── start-wrangler/
    ├── README.md
    ├── start-wrangler
    └── start-wrangler.completion
```

---

## 🛠️ 공통 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 환경(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../utils/scriptctl/scriptctl install --script ./start-wrangler/start-wrangler --target local
../utils/scriptctl/scriptctl install --script ./init-wrangler-d1/init-wrangler-d1 --target local
../utils/scriptctl/scriptctl install --script ./migration-d1-init-scheme/migration-d1-init-scheme --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../utils/scriptctl/scriptctl install --script ./start-wrangler/start-wrangler --target global
../utils/scriptctl/scriptctl install --script ./init-wrangler-d1/init-wrangler-d1 --target global
../utils/scriptctl/scriptctl install --script ./migration-d1-init-scheme/migration-d1-init-scheme --target global
```
