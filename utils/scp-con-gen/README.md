# scp-con-gen

원격 접속 정보(계정, 비밀번호, 호스트, 포트, 원격 디렉토리)를 인자로 받아, `sshpass`와 `scp`를 통해 대상 서버로 파일을 자동으로 전송할 수 있는 독립 실행형 쉘 스크립트를 생성해 주는 전송 스크립트 자동 생성 도구입니다.

---

## ✨ 주요 특징

- **자동 전송 래퍼 스크립트 생성**: 비밀번호 입력 과정을 `sshpass`로 자동화한 전용 파일 전송 쉘 스크립트를 즉시 생성합니다.
- **실행 권한 자동 부여**: 생성된 전송 스크립트에 자동으로 실행 권한(`chmod +x`)을 부여합니다.
- **특수문자 비밀번호 안전 가이드**: 비밀번호에 느낌표(`!`) 등 쉘 특수문자가 포함된 경우 작은따옴표(`'...'`)로 안전하게 감싸서 전달할 수 있습니다.
- **지능형 Bash 자동완성**: 파라미터 옵션 자동완성을 완벽하게 지원합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--user <계정명>` | **필수** | 원격 SSH 접속 계정 |
| `--password <비밀번호>` | **필수** | 원격 SSH 접속 비밀번호 (특수문자 포함 시 `'...'` 권장) |
| `--host <호스트>` | **필수** | 원격 서버 IP 주소 또는 도메인 |
| `--port <포트>` | **필수** | SSH 포트 번호 (기본 22 등) |
| `--dir <원격경로>` | **필수** | 파일을 전송할 원격 서버의 목적지 디렉토리 경로 |
| `--file <출력파일명>` | **필수** | 생성할 전송 스크립트 파일명 |
| `--help` | 선택 | 도움말 메시지를 표시합니다. |

---

## 🚀 사용 예시

### 1. 원격 배포용 전송 스크립트 생성
```bash
scp-con-gen \
  --user devuser \
  --password 'SecretPass123!' \
  --host 192.168.1.100 \
  --port 22 \
  --dir /opt/services/deploy \
  --file send-artifact.sh
```

### 2. 생성된 스크립트로 파일 전송 실행
```bash
./send-artifact.sh ./build-output.tar.gz
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../scriptctl/scriptctl install --script ./scp-con-gen --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../scriptctl/scriptctl install --script ./scp-con-gen --target global
```
