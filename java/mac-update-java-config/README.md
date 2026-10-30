# mac-update-java-config

`mac-update-java-config`는 macOS 환경에서 `jenv`에 등록된 다양한 JDK 버전들을 조회하고, 사용자가 선택한 버전을 `jenv global` 및 `JAVA_HOME` 환경 변수에 대화형으로 즉시 동기화해 주는 CLI 도구입니다.

---

## ✨ 주요 특징

- **jenv 등록 버전 자동 조회 및 필터링**: `jenv versions`에서 실제 설치된 유효한 숫자 기반 Java 버전들을 필터링하여 목록을 제공합니다.
- **물리적 JDK 경로 매핑**: 각 버전의 실제 바이너리 및 홈 디렉토리를 `realpath`로 역추적하여 경로를 함께 표시합니다.
- **JAVA_HOME 명시적 설정**: `/usr/libexec/java_home`을 통해 현재 선택된 버전에 맞는 `JAVA_HOME` 경로를 정확히 추출하여 안내합니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 대화형(Interactive) 실행을 기본으로 하며, **Long Option** 전용으로 동작합니다.

| 파라미터 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--help` | 선택 | 사용법 및 도움말 안내 출력 |

---

## 🚀 사용 예시

### 기본 대화형 실행
```bash
mac-update-java-config
```
실행 후 번호를 선택하면 `jenv global` 및 `JAVA_HOME`이 갱신됩니다.

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./mac-update-java-config --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./mac-update-java-config --target global
```
