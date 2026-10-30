# fail2ban

Fail2ban 보안 침입 차단 및 IP 관리 유틸리티 도구를 제공하는 디렉토리입니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | 설명 | 지원 기능 |
| :--- | :--- | :--- |
| [`fail2ban-unbanip`](./fail2ban-unbanip/README.md) | Fail2ban Jail 차단 현황 조회 및 대화형 IP 차단 해제 도구 | 활성 Jail 및 차단 IP 목록 테이블 시각화, 대화형 번호 선택 해제, 다중 IP 일괄 해제, 실시간 결과 검증 |

---

## 📁 디렉토리 구조

```plaintext
fail2ban/
├── README.md
└── fail2ban-unbanip/
    ├── README.md
    ├── fail2ban-unbanip
    └── fail2ban-unbanip.completion
```

---

## 🛠️ 공통 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 환경(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../utils/scriptctl/scriptctl install --script ./fail2ban-unbanip/fail2ban-unbanip --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../utils/scriptctl/scriptctl install --script ./fail2ban-unbanip/fail2ban-unbanip --target global
```
