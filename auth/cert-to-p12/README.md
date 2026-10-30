# 🔐 cert-to-p12

PEM 형식의 SSL/TLS 인증서(`--cert`), 개인키(`--privkey`), 체인 인증서(`--chain`) 파일을 입력받아 OpenSSL 기반으로 표준 **PKCS#12(`.p12`) 키스토어 파일**로 변환하는 CLI 유틸리티입니다.

---

## ✨ 주요 특징

1. **표준 PKCS#12(`.p12`) 번들 변환**
   * 서버 인증서, 개인키, CA 체인 파일을 하나의 암호화된 `.p12` 파일로 통합 생성하여 Java(Spring Boot/Tomcat) 및 다양한 웹 서버에 즉시 적용할 수 있습니다.
2. **사전 파일 무결성 및 덮어쓰기 보호**
   * 변환 전 입력 PEM 파일들의 존재 여부를 검증하며, 동일한 이름의 `.p12` 출력 파일이 이미 존재할 경우 사용자 확인을 거쳐 안전하게 처리합니다.
3. **개인키 암호(`-passin`) 대화형 지원**
   * 원본 PEM 개인키에 암호가 설정되어 있는 경우 대화형 프롬프트를 통해 입력받아 안전하게 복호화 및 변환을 수행합니다.
4. **지능형 Bash 자동완성 (`cert-to-p12.completion`)**
   * 이미 입력한 옵션은 중복 추천에서 제외하며, 파일 경로가 필요한 옵션 뒤에서는 파일/디렉토리 경로 자동완성을 제공합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--cert <파일경로>` | **필수** | - | 변환할 PEM 인증서 파일 경로 (예: `cert.pem`, `fullchain.pem`) |
| `--privkey <파일경로>` | **필수** | - | 변환할 PEM 개인키 파일 경로 (예: `privkey.pem`) |
| `--chain <파일경로>` | **필수** | - | 함께 번들링할 PEM CA 체인 파일 경로 (예: `chain.pem`) |
| `--pkcs12-file <파일경로>` | **필수** | - | 생성할 PKCS#12(`.p12`) 출력 파일 경로 |
| `--pkcs12-password <비밀번호>` | **필수** | - | 생성될 PKCS#12 파일에 설정할 내보내기(Export) 비밀번호 |
| `--help` | 선택 | - | 도움말 메시지를 출력하고 종료합니다. |

---

## 🚀 사용 예시

### 1. Let's Encrypt PEM 파일들을 PKCS#12(`.p12`) 파일로 변환
```bash
cert-to-p12 \
  --cert ./cert1.pem \
  --privkey ./privkey1.pem \
  --chain ./chain1.pem \
  --pkcs12-file ./keystore.p12 \
  --pkcs12-password "MySecretPassword123!"
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../../utils/scriptctl/scriptctl install --script ./cert-to-p12 --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../../utils/scriptctl/scriptctl install --script ./cert-to-p12 --target global
```
