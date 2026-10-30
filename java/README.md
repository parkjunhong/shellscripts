# java

Java 환경 변수(`JAVA_HOME`) 설정, 버전 전환 및 링크 관리 유틸리티 도구를 제공하는 디렉토리입니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | 지원 OS | 설명 | 지원 기능 |
| :--- | :---: | :--- | :--- |
| [`update-java-config`](./update-java-config/README.md) | **Linux** | Linux Java 버전 전환 및 `~/.java_env` 생성 도구 | `update-alternatives` 연동, 물리 경로 역추적, 환경 파일 생성 |
| [`mac-update-java-config`](./mac-update-java-config/README.md) | **macOS** | macOS `jenv` 기반 Java 버전 전환 도구 | `jenv` 등록 버전 탐색, `jenv global` 및 `JAVA_HOME` 동기화 |
| [`mac-clean-java-config`](./mac-clean-java-config/README.md) | **macOS** | macOS `jenv` 깨진 심볼릭 링크 정리 도구 | 깨진 JDK 링크 감지, 삭제 전 목록 확인 및 일괄 정리 |

---

## 📁 디렉토리 구조

```plaintext
java/
├── README.md
├── mac-clean-java-config/
│   ├── README.md
│   ├── mac-clean-java-config
│   └── mac-clean-java-config.completion
├── mac-update-java-config/
│   ├── README.md
│   ├── mac-update-java-config
│   └── mac-update-java-config.completion
└── update-java-config/
    ├── README.md
    ├── update-java-config
    └── update-java-config.completion
```

---

## 🛠️ 공통 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 환경(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../utils/scriptctl/scriptctl install --script ./update-java-config/update-java-config --target local
../utils/scriptctl/scriptctl install --script ./mac-update-java-config/mac-update-java-config --target local
../utils/scriptctl/scriptctl install --script ./mac-clean-java-config/mac-clean-java-config --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../utils/scriptctl/scriptctl install --script ./update-java-config/update-java-config --target global
../utils/scriptctl/scriptctl install --script ./mac-update-java-config/mac-update-java-config --target global
../utils/scriptctl/scriptctl install --script ./mac-clean-java-config/mac-clean-java-config --target global
```
