# 🔐 Auth & Certificate Lifecycle Management Shell Scripts

Let's Encrypt 기반 단일 도메인 인증서 일괄 발급(`request-letsenc-single-cert`), DNS 챌린지 기반 와일드카드 인증서 발급·갱신(`request-letsenc-wildcard-cert`), PEM 인증서의 PKCS#12(`.p12`) 키스토어 변환(`cert-to-p12`), 그리고 발급된 인증서를 4종 포맷(`pem`, `sslca`, `pkcs12`, `jks`)으로 일괄 변환하여 원격 서버들에 배포 및 재기동하는 통합 배포 자동화(`send-certificate`)를 지원하는 표준 CLI 인증서 관리 도구 모음입니다.

모든 도구는 독립 실행형 Canonical 디렉토리 구조(`auth/<tool>/<tool>`), 최신 표준 Bash 자동완성(`.completion`), 그리고 상세한 개별 `README.md`를 갖추고 있습니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | Canonical 경로 | 주요 기능 및 특징 | Bash 자동완성 | 개별 문서 |
| :--- | :--- | :--- | :---: | :---: |
| **cert-to-p12** | [`cert-to-p12/`](cert-to-p12/cert-to-p12) | PEM 인증서(`--cert`), 개인키(`--privkey`), 체인(`--chain`)을 표준 PKCS#12(`.p12`) 파일로 변환 | ✅ 지원 | [상세보기](cert-to-p12/README.md) |
| **request-letsenc-single-cert** | [`request-letsenc-single-cert/`](request-letsenc-single-cert/request-letsenc-single-cert) | 다중 도메인 목록(`--domains`, `--file`)에 대해 `certbot --standalone` 기반 단일 인증서 일괄 발급 | ✅ 지원 | [상세보기](request-letsenc-single-cert/README.md) |
| **request-letsenc-wildcard-cert** | [`request-letsenc-wildcard-cert/`](request-letsenc-wildcard-cert/request-letsenc-wildcard-cert) | `certbot` 수동 DNS 챌린지를 통한 루트 및 와일드카드(`*.<domain>`) 인증서 발급·갱신 | ✅ 지원 | [상세보기](request-letsenc-wildcard-cert/README.md) |
| **send-certificate** | [`send-certificate/`](send-certificate/send-certificate) | 와일드카드 인증서 4종 포맷(`pem`, `sslca`, `pkcs12`, `jks`) 일괄 변환 및 다중 원격 서버 배포·재기동 | ✅ 지원 | [상세보기](send-certificate/README.md) |

---

## 📂 디렉토리 구조

```text
auth/
├── README.md                                           # Auth 도구 종합 안내 (본 문서)
├── cert-to-p12/
│   ├── cert-to-p12                                     # PEM -> PKCS#12(.p12) 변환 도구
│   ├── cert-to-p12.completion                          # Bash 자동완성 스크립트
│   └── README.md                                       # 개별 도구 상세 설명서
├── request-letsenc-single-cert/
│   ├── request-letsenc-single-cert                     # 다중 단일 도메인 Let's Encrypt 인증서 발급 도구
│   ├── request-letsenc-single-cert.completion          # Bash 자동완성 스크립트
│   └── README.md                                       # 개별 도구 상세 설명서
├── request-letsenc-wildcard-cert/
│   ├── request-letsenc-wildcard-cert                   # 와일드카드 Let's Encrypt 인증서 발급/갱신 도구
│   ├── request-letsenc-wildcard-cert.completion        # Bash 자동완성 스크립트
│   └── README.md                                       # 개별 도구 상세 설명서
└── send-certificate/
    ├── send-certificate                                # 인증서 4종 포맷 변환 및 다중 서버 원격 배포 도구
    ├── send-certificate.completion                     # Bash 자동완성 스크립트
    ├── services-list.txt                               # 원격 배포 대상 서버 및 사후 명령어 설정 템플릿
    └── README.md                                       # 개별 도구 상세 설명서
```

---

## 🛠️ 공통 설치 안내

각 도구는 독립 실행형 CLI 도구로, 저장소의 `utils/scriptctl` 유틸리티를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로(`/usr/local/bin`)에 간편하게 설치할 수 있습니다. 스크립트 설치 시 연관된 Bash 자동완성 규칙이 시스템 표준 경로(`/usr/share/bash-completion/completions/`)에 자동으로 등록됩니다.

### `scriptctl` 도구를 사용한 설치

```bash
# 개인 환경 설치 예시 (~/bin, 사용자 자동완성 등록)
../utils/scriptctl/scriptctl install --script ./cert-to-p12/cert-to-p12 --target local
../utils/scriptctl/scriptctl install --script ./request-letsenc-single-cert/request-letsenc-single-cert --target local
../utils/scriptctl/scriptctl install --script ./request-letsenc-wildcard-cert/request-letsenc-wildcard-cert --target local
../utils/scriptctl/scriptctl install --script ./send-certificate/send-certificate --target local

# 시스템 전역 설치 예시 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
# ※ 주의: scriptctl 자체의 권한 상승 차단을 위해 명령어 앞에 sudo를 붙이지 않습니다.
../utils/scriptctl/scriptctl install --script ./send-certificate/send-certificate --target global
```
