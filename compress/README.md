# compress

압축 및 아카이빙 관련 유틸리티 도구를 제공하는 디렉토리입니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | 설명 | 지원 기능 |
| :--- | :--- | :--- |
| [`tar-dirs`](./tar-dirs/README.md) | 하위 디렉토리 개별 `.tar.gz` 일괄 압축 도구 | 포함/제외 필터링, 출력 디렉토리 지정, Dry-run 지원 |

---

## 📁 디렉토리 구조

```plaintext
compress/
├── README.md
└── tar-dirs/
    ├── README.md
    ├── tar-dirs
    └── tar-dirs.completion
```

---

## 🛠️ 공통 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 환경(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../utils/scriptctl/scriptctl install --script ./tar-dirs/tar-dirs --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../utils/scriptctl/scriptctl install --script ./tar-dirs/tar-dirs --target global
```
