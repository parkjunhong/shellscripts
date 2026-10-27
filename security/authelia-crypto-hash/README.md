# 🔐 authelia-crypto-hash

Docker 컨테이너 환경에서 Authelia 인증 시스템에 사용되는 강력한 암호화 해시(Argon2id, bcrypt, pbkdf2, scrypt, sha2crypt)를 안전하게 생성하는 CLI 도구입니다.

---

## ✨ 주요 특징

1. **안전한 비밀번호 마스킹 입력 및 복잡도 정책 검증**
   * 커맨드라인 히스토리에 평문 비밀번호가 남지 않도록 대화형 마스킹 입력을 제공합니다.
   * 엄격한 보안 정책(최소 10자, 대/소문자·숫자·특수문자 조합, 3개 이상 연속/동일 문자 제한)을 내장 검증합니다 (개발 테스트용 'test' 예외 허용).
2. **Docker 독립 컨테이너 기반 생성**
   * 호스트에 별도의 Authelia 바이너리나 종속성을 설치할 필요 없이, 공식 Docker 이미지를 통해 원클릭으로 해시를 생성합니다.
3. **동시 실행 충돌 방지**
   * 난수 기반의 임시 고유 컨테이너명을 생성하고 완료 즉시 자동 제거(`--rm`)하여 다중 사용자 및 동시 작업 환경에서도 안전합니다.
4. **다양한 해시 알고리즘 지원**
   * `argon2` (기본값), `bcrypt`, `pbkdf2`, `scrypt`, `sha2crypt` 등 Authelia가 지원하는 모든 표준 해시 알고리즘을 지원합니다.
5. **지능형 Bash 자동 완성 (`authelia-crypto-hash.completion`)**
   * 옵션 자동 완성뿐만 아니라 로컬에 다운로드된 Authelia Docker 이미지 목록 및 지원 알고리즘 목록을 동적으로 추천합니다.

---

## ⚙️ 파라미터 명세

```bash
authelia-crypto-hash [옵션]
```

| 옵션 | 기본값 | 설명 |
| :--- | :---: | :--- |
| `--algorithm <알고리즘>` | `argon2` | 해시 알고리즘 (`argon2`, `bcrypt`, `pbkdf2`, `scrypt`, `sha2crypt`) |
| `--image <이미지명>` | `authelia/authelia:latest` | 실행에 사용할 Authelia Docker 이미지 |
| `--help` | - | 도움말 메시지 출력 및 종료 |

---

## 🚀 사용 예시

```bash
# 1) 기본 설정으로 실행 (Argon2id 알고리즘, 대화형 비밀번호 입력)
./authelia-crypto-hash

# 2) bcrypt 알고리즘으로 해시 생성
./authelia-crypto-hash --algorithm bcrypt

# 3) 특정 버전의 Authelia Docker 이미지 지정
./authelia-crypto-hash --image authelia/authelia:4.38.0 --algorithm argon2
```
