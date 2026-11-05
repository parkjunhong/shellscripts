# 🚀 install-update-java-config

시스템에 설치된 여러 Java(JDK) 버전 간 전환을 손쉽게 제어하는 **`update-java-config`** 유틸리티를 사용자의 `~/bin`에 설치하고, 쉘 환경 변수(`JAVA_HOME`, `PATH`)가 현재 세션 및 신규 터미널에 영구히 유지되도록 쉘 설정 파일에 자동 래퍼를 등록하는 설치 스크립트입니다.

---

## ✨ 주요 특징

1. **도구 자동 설치**:
   * 저장소의 `java/update-java-config` (macOS의 경우 `mac-update-java-config`) 최신 버전을 `~/bin/update-java-config`로 다운로드 및 실행 권한을 부여합니다.
2. **쉘 동기화 래퍼 함수 자동 등록**:
   * Linux는 `~/.bashrc`, macOS는 `~/.bash_profile`에 `function update-java-config()` 래퍼 함수를 주입합니다.
   * 터미널에서 버전을 변경하면 `source ~/.java_env`를 즉시 호출하여 현재 열려 있는 쉘에 `JAVA_HOME`이 즉각 반영됩니다.
   * 새 터미널이나 시스템 재부팅 시에도 선택된 버전이 지속 유지됩니다.

---

## ⚙️ 사용법

### 1. `sciectl`을 통한 실행
```bash
sciectl install --installer install-update-java-config
```

### 2. 단독 직접 실행
```bash
./install-update-java-config
```
