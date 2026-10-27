# Sudo & Privilege Management Shell Scripts

리눅스 시스템 계정 및 그룹의 Sudo 권한 정책 관리, `/etc/sudoers.d/` 기반 모듈식 정책 제어 및 `visudo` 사전 문법 검증을 통한 무결성 보장을 제공하는 표준 CLI 관리 도구 모음입니다.

모든 도구는 독립 실행형 Canonical 디렉토리 구조(`sudo/<tool>/<tool>`), 리눅스 표준 Bash 자동완성(`.completion`), 그리고 상세한 개별 `README.md`를 갖추고 있습니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | Canonical 경로 | 주요 기능 및 특징 | Bash 자동완성 | 개별 문서 |
| :--- | :--- | :--- | :---: | :---: |
| **sudoers-cli** | [`sudoers-cli/`](sudoers-cli/sudoers-cli) | 계정/그룹별 Sudoers 정책 파일 생성·병합, 패키지 설치 연동 및 `visudo` 사전 검증·롤백 | ✅ 지원 | [상세보기](sudoers-cli/README.md) |

---

## 📂 디렉토리 구조

```text
sudo/
├── README.md                           # Sudo 도구 종합 안내 (본 문서)
└── sudoers-cli/
    ├── sudoers-cli                    # Sudoers 정책 관리 및 visudo 검증 CLI 도구
    ├── sudoers-cli.completion         # Bash 자동완성 스크립트
    └── README.md                      # 개별 도구 상세 설명서
```

---

## 🛠️ 공통 설치 안내

각 도구는 독립 실행형 CLI 도구로, 저장소의 `utils/scriptctl` 유틸리티를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로(`/usr/local/bin`)에 간편하게 설치할 수 있습니다. 스크립트 설치 시 연관된 Bash 자동완성 규칙이 시스템 표준 경로(`/usr/share/bash-completion/completions/`)에 자동으로 등록됩니다.

### `scriptctl` 도구를 사용한 설치

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../utils/scriptctl/scriptctl install --script ./sudoers-cli/sudoers-cli --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
# ※ 주의: scriptctl 자체의 권한 상승 차단을 위해 명령어 앞에 sudo를 붙이지 않습니다.
../utils/scriptctl/scriptctl install --script ./sudoers-cli/sudoers-cli --target global
```
