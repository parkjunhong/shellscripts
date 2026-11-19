# 🌐 Nginx Shell Scripts

Nginx 웹 서버의 설정 관리, 가상 호스트 옵션 제어, 성능 최적화 및 운영 자동화를 지원하는 표준 CLI 도구 모음입니다.

모든 도구는 독립 실행형 Canonical 디렉토리 구조(`nginx/<tool>/<tool>`), 표준 Bash 자동완성(`.completion`), Unix 매뉴얼 페이지(`man/man1/`), 그리고 상세한 개별 `README.md`를 갖추고 있습니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | Canonical 경로 | 주요 기능 및 특징 | Bash 자동완성 | 매뉴얼 (`man`) | 개별 문서 |
| :--- | :--- | :--- | :---: | :---: | :---: |
| **ngxconf-ctl** | [`ngxconf-ctl/`](ngxconf-ctl/ngxconf-ctl) | Nginx 버전 감지 기반 가상 호스트 설정 파일(`*.conf`)의 HTTP/2 활성화/비활성화 제어 CLI | ✅ 지원 | [ngxconf-ctl(1)](ngxconf-ctl/man/man1/ngxconf-ctl.1) | [상세보기](ngxconf-ctl/README.md) |

---

## 📂 디렉토리 구조

```text
nginx/
├── README.md                                   # Nginx 도구 종합 안내 (본 문서)
└── ngxconf-ctl/
    ├── ngxconf-ctl                             # Nginx 설정 옵션(HTTP/2) 제어 CLI 도구
    ├── ngxconf-ctl.completion                  # Bash 자동완성 스크립트
    ├── README.md                               # 개별 도구 상세 설명서
    └── man/
        └── man1/
            └── ngxconf-ctl.1                   # Unix 표준 매뉴얼 페이지 (Section 1)
```

---

## 🛠️ 공통 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트와 `man` 매뉴얼 페이지도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 1) 개인 환경 설치 (~/bin, 사용자 자동완성 및 매뉴얼 등록)
../utils/scriptctl/scriptctl install --script ./ngxconf-ctl/ngxconf-ctl --target local

# 2) 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/, /usr/share/man/ 등록)
# ※ 주의: scriptctl 자체의 권한 상승 차단을 위해 명령어 앞에 sudo를 붙이지 않습니다.
../utils/scriptctl/scriptctl install --script ./ngxconf-ctl/ngxconf-ctl --target global
```
