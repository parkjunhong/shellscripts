# 🔑 env/keys (SSH RSA 공개키 저장소)

`env/keys/` 디렉토리는 서버 프로비저닝 시 `~/.ssh/authorized_keys`에 안전하게 자동 배포될 **공식 SSH RSA 공개키(*.pub)**를 관리합니다.

사용자 지침에 따라 실행 스크립트와 구별하여 **디렉토리별 격리 및 `.pub` 확장자 보존**, 그리고 키의 소유권과 발급 목적을 명시한 `README.md` 문서를 함께 유지합니다.

---

## 📋 등록된 공개키 목록

| 키 식별자 | Canonical 디렉토리 | 공개키 파일 | 발급 목적 및 대상 |
| :--- | :--- | :--- | :--- |
| `letsencrypt` | [`letsencrypt`](./letsencrypt/) | `letsencrypt.pub` | Let's Encrypt SSL/TLS 인증서 자동 갱신 및 배포용 자동화 에이전트 키 |
| `ymtech-internal` | [`ymtech-internal`](./ymtech-internal/) | `ymtech-internal.pub` | 사내 내부 인프라 관리, 원격 유지보수 및 공통 서버 접근용 공개키 |

---

## 🔒 보안 및 관리 지침

1. **개인키(Private Key) 절대 커밋 금지**:
   * 이 저장소에는 오직 공개키(`*.pub`)만 저장되어야 하며, 개인키는 보안 키 관리소(KMS, Vault) 또는 보안 USB에 격리 보관되어야 합니다.
2. **`sciectl`을 통한 자동 등록 원칙**:
   * `sciectl`은 등록 전 Base64 본문 해시를 검사하여 `authorized_keys`에 이미 등록된 키인 경우 중복 추가를 방지합니다.
   * `~/.ssh` 디렉토리(700) 및 `authorized_keys` 파일(600)의 보안 퍼미션을 자동으로 교정합니다.

---

## ⚙️ 등록 사용법

### 1. `sciectl`을 통한 등록 (권장)
```bash
# 카탈로그를 통한 일괄 등록
sciectl install --catalog default-server

# 특정 키만 단독 등록
sciectl install --ssh-key letsencrypt
sciectl install --ssh-key ymtech-internal
```
