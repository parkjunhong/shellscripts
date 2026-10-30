# sqlldr

Oracle SQL*Loader 관련 로그 분석 및 데이터 로딩 지원 유틸리티 도구를 제공하는 디렉토리입니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | 설명 | 지원 기능 |
| :--- | :--- | :--- |
| [`match-error-lnb`](./match-error-lnb/README.md) | Oracle SQL*Loader 에러 로그와 Badfile 라인 매핑 도구 | 거부 레코드 정규식 감지, 원본-badfile 라인 번호 매핑, 진행률 표시 |

---

## 📁 디렉토리 구조

```plaintext
sqlldr/
├── README.md
└── match-error-lnb/
    ├── README.md
    ├── match-error-lnb
    └── match-error-lnb.completion
```

---

## 🛠️ 공통 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 환경(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../utils/scriptctl/scriptctl install --script ./match-error-lnb/match-error-lnb --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../utils/scriptctl/scriptctl install --script ./match-error-lnb/match-error-lnb --target global
```
