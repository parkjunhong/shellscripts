# antigravity

Google Antigravity Core CLI 및 Antigravity IDE 설치 및 환경 구성을 지원하는 도구 모음 디렉토리입니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | 설명 | 지원 기능 |
| :--- | :--- | :--- |
| [`install-antigravity-x64`](./install-antigravity-x64/README.md) | Antigravity Core/CLI x64 버전 설치 도구 | 공식 저장소 버전 목록 동적 조회, 대화형 선택 설치, 데스크톱 바로가기/심볼릭 링크 등록, Dry-run 지원 |
| [`install-antigravity-ide`](./install-antigravity-ide/README.md) | Antigravity IDE 설치 도구 | 공식 저장소 2.x+ 버전 동적 조회, Electron 샌드박스 보안 설정, 데스크톱 바로가기 등록, Dry-run 지원 |

---

## 📁 디렉토리 구조

```plaintext
antigravity/
├── README.md
├── install-antigravity-ide/
│   ├── README.md
│   ├── install-antigravity-ide
│   └── install-antigravity-ide.completion
└── install-antigravity-x64/
    ├── README.md
    ├── install-antigravity-x64
    └── install-antigravity-x64.completion
```

---

## 🛠️ 공통 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 환경(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../utils/scriptctl/scriptctl install --script ./install-antigravity-x64/install-antigravity-x64 --target local
../utils/scriptctl/scriptctl install --script ./install-antigravity-ide/install-antigravity-ide --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../utils/scriptctl/scriptctl install --script ./install-antigravity-x64/install-antigravity-x64 --target global
../utils/scriptctl/scriptctl install --script ./install-antigravity-ide/install-antigravity-ide --target global
```
