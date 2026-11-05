# 🚀 install-update-mvn-config

시스템에 설치된 여러 Apache Maven 버전 간 전환을 손쉽게 제어하는 **`update-mvn-config`** 유틸리티를 사용자의 `~/bin`에 설치하고, 쉘 환경 변수(`M2_HOME`, `MAVEN_HOME`, `PATH`)가 현재 세션 및 신규 세션에 자동으로 유지되도록 쉘 설정 파일에 래퍼를 등록하는 설치 스크립트입니다.

---

## ✨ 주요 특징

1. **도구 자동 설치**:
   * 저장소의 `maven/update-mvn-config` 최신 버전을 `~/bin/update-mvn-config`로 다운로드 및 실행 권한을 부여합니다.
2. **쉘 동기화 래퍼 함수 자동 등록**:
   * Linux는 `~/.bashrc`, macOS는 `~/.bash_profile`에 `function update-mvn-config()` 래퍼 함수를 주입합니다.
   * 버전 변경 즉시 `source ~/.maven_env`가 실행되어 현재 쉘 환경에 새 Maven 경로가 즉시 적용됩니다.
   * OS 재부팅 및 새 터미널 생성 시에도 설정된 Maven 버전이 유지됩니다.

---

## ⚙️ 사용법

### 1. `sciectl`을 통한 실행
```bash
sciectl install --installer install-update-mvn-config
```

### 2. 단독 직접 실행
```bash
./install-update-mvn-config
```
