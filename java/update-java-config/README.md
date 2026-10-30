# update-java-config

`update-java-config`는 Linux 계열(Ubuntu, RHEL, Rocky Linux 등) OS에서 `update-alternatives`를 통해 Java 버전을 대화형으로 선택하고, 선택된 JDK의 실제 물리적 경로를 추적하여 `~/.java_env` 파일에 `JAVA_HOME`을 자동으로 등록하는 CLI 도구입니다.

---

## ✨ 주요 특징

- **OS 표준 연동**: Linux 배포판의 표준 대체 관리자인 `update-alternatives --config java` 인터페이스를 직접 호출합니다.
- **물리적 경로 자동 해석**: 심볼릭 링크 체인을 역추적(`readlink -f`)하여 실제 JDK 홈 디렉토리를 안전하게 추출합니다.
- **환경 변수 파일 생성**: `~/.java_env` 파일에 `export JAVA_HOME="..."`을 자동으로 기록하여 새 터미널 및 쉘 세션에서 영구적으로 유지되도록 지원합니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 대화형(Interactive) 실행을 기본으로 하며, **Long Option** 전용으로 동작합니다.

| 파라미터 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--help` | 선택 | 사용법 및 도움말 안내 출력 |

---

## 🚀 사용 예시

### 1. 기본 대화형 실행
```bash
update-java-config
```
실행 후 번호를 선택하면 선택된 JDK 경로가 `~/.java_env`에 기록됩니다.

### 2. 쉘 환경 자동 동기화 설정 권장 (`~/.bashrc`)
새 터미널 오픈 시 자동으로 적용되도록 `~/.bashrc`에 다음 설정을 추가하는 것을 권장합니다:
```bash
if [ -f ~/.java_env ]; then
    source ~/.java_env
fi
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./update-java-config --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./update-java-config --target global
```
