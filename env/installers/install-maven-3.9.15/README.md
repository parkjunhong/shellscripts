# 🚀 install-maven-3.9.15

Apache 공식 아카이브 저장소에서 **Apache Maven 3.9.15** 바이너리 배포판을 다운로드하여 시스템 전역 경로(`/opt/apache-maven-3.9.15`)에 설치하는 스크립트입니다.

---

## ✨ 주요 특징

1. **공식 아카이브 다운로드**:
   * `https://archive.apache.org/dist/maven/maven-3/3.9.15/binaries/apache-maven-3.9.15-bin.tar.gz`에서 공식 무결성 보장 패키지를 수취합니다.
2. **시스템 표준 설치 경로**:
   * `/opt/apache-maven-3.9.15` 경로에 압축을 해제하여 다중 Maven 버전 관리 환경(`update-mvn-config`)과 유기적으로 연동될 수 있도록 구성합니다.
3. **설치 멱등성 보장**:
   * 대상 디렉토리가 이미 존재할 경우 다운로드 및 설치를 건너뜁니다.

---

## ⚙️ 사용법

### 1. `sciectl`을 통한 실행
```bash
sciectl install --installer maven-3.9.15
```

### 2. 단독 직접 실행
```bash
./install-maven-3.9.15
```

---

## 📋 시스템 요구사항
* Linux 환경 (`/opt` 쓰기 권한을 위한 `sudo`)
* `curl`, `tar` 유틸리티
