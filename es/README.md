# es

Elasticsearch 모니터링, 통계 및 데이터 검색 유틸리티 도구를 제공하는 디렉토리입니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | 설명 | 지원 기능 |
| :--- | :--- | :--- |
| [`es-index-usage`](./es-index-usage/README.md) | Elasticsearch 인덱스별 샤드/문서수/저장용량 통계 집계 도구 | 샤드 수, 문서 수, 용량(GB/TB) 정밀 계산, 접두어 지원 |
| [`es-search-index`](./es-search-index/README.md) | Elasticsearch 타임스탬프 범위 기반 문서 검색 및 필드 추출 도구 | 타임스탬프 범위 조회, 특정 필드 추출, 크기 제어 |

---

## 📁 디렉토리 구조

```plaintext
es/
├── README.md
├── es-index-usage/
│   ├── README.md
│   ├── es-index-usage
│   └── es-index-usage.completion
└── es-search-index/
    ├── README.md
    ├── es-search-index
    └── es-search-index.completion
```

---

## 🛠️ 공통 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 환경(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../utils/scriptctl/scriptctl install --script ./es-index-usage/es-index-usage --target local
../utils/scriptctl/scriptctl install --script ./es-search-index/es-search-index --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../utils/scriptctl/scriptctl install --script ./es-index-usage/es-index-usage --target global
../utils/scriptctl/scriptctl install --script ./es-search-index/es-search-index --target global
```
