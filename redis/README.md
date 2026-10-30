# redis

Redis 데이터베이스 조회, 검색, 스캔 및 정규식 필터링 도구를 제공하는 디렉토리입니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | 설명 | 지원 기능 |
| :--- | :--- | :--- |
| [`redis-search`](./redis-search/README.md) | Redis 고급 검색, 정규식 필터링 및 커서 기반 전체 스캔 도구 | 정규식 필터링(`__filter_in__`, `__filter_out__`), 안전한 커서 스캔(`__get_all__`), Key-Value 동시 출력 |

---

## 📁 디렉토리 구조

```plaintext
redis/
├── README.md
└── redis-search/
    ├── README.md
    ├── redis-search
    └── redis-search.completion
```

---

## 🛠️ 공통 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 환경(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../utils/scriptctl/scriptctl install --script ./redis-search/redis-search --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../utils/scriptctl/scriptctl install --script ./redis-search/redis-search --target global
```
