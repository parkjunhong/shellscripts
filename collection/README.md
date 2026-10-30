# collection

데이터 컬렉션 및 매핑 관련 유틸리티 도구를 제공하는 디렉토리입니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | 설명 | 지원 기능 |
| :--- | :--- | :--- |
| [`csv-to-map`](./csv-to-map/README.md) | CSV 컬럼 인덱스 기반 키-값 매핑 파일 생성 도구 | 인덱스 기반 Key-Value 추출, 인용 부호 파싱, 헤더 건너뛰기, 진행률 표시 |

---

## 📁 디렉토리 구조

```plaintext
collection/
├── README.md
└── csv-to-map/
    ├── README.md
    ├── csv-to-map
    └── csv-to-map.completion
```

---

## 🛠️ 공통 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 환경(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../utils/scriptctl/scriptctl install --script ./csv-to-map/csv-to-map --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../utils/scriptctl/scriptctl install --script ./csv-to-map/csv-to-map --target global
```
