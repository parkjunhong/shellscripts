# update-mvn-config

시스템(기본 `/opt`)에 설치된 다양한 버전의 Apache Maven(`apache-maven-*`) 디렉토리를 탐색하여 대화형 목록을 제공하고, 사용자가 선택한 버전으로 `M2_HOME`, `MAVEN_HOME`, `PATH` 환경 변수를 갱신하는 Maven 버전 관리 및 스위칭 도구입니다.

---

## ✨ 주요 특징

- **대화형 버전 전환 (Interactive Selection)**: 설치된 모든 Maven 디렉토리를 번호 기반 메뉴로 출력하여 간편하게 활성 버전을 선택할 수 있습니다.
- **안전한 디렉토리 필터링**: 압축 아카이브(`.tar.gz` 등)를 제외하고 실제 설치된 유효 디렉토리만 목록에 노출합니다.
- **PATH 오염 방지 및 정규화**: 기존 `PATH`에 남아있는 이전 구버전 Maven 경로를 완벽히 정제한 후 신규 버전 경로를 최상단에 주입합니다.
- **영구적인 환경 변수 유지**: `~/.maven_env` 파일을 자동 생성하여 새 터미널 창을 열거나 OS 재부팅 후에도 마지막으로 선택한 Maven 버전을 유지합니다.
- **현재 쉘 즉각 반영 지원**: `~/.bashrc` 내 래퍼 함수를 통해 선택 즉시 현재 터미널 환경에 동기화할 수 있습니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--help` | 선택 | 도구 사용법 및 환경 설정 안내를 출력합니다. |

---

## 🚀 사용 예시

### 1. 버전 전환 대화형 실행
```bash
update-mvn-config
```

**실행 화면 예시:**
```text
대체 항목 maven에 대해 선택할 수 있는 버전이 있습니다.
  선택       경로
------------------------------------------------------------
  0          /opt/apache-maven-3.6.3
  1          /opt/apache-maven-3.8.8
  2          /opt/apache-maven-3.9.6

선택 번호를 입력하시오: 2
[System] Maven 설정이 갱신되었습니다: /opt/apache-maven-3.9.6
```

---

## 🔧 필수 쉘 환경 설정 (`~/.bashrc`)

`update-mvn-config` 실행 결과를 현재 터미널 세션에 즉각 적용하고, 신규 터미널 세션에서도 지속되도록 하려면 아래 스크립트를 `~/.bashrc`에 추가하세요.

```bash
# ==========================================
# Maven 환경 변수 관리 (update-mvn-config 연동)
# ==========================================

# 1. 신규 쉘 및 재부팅 시 마지막 설정 복원
if [ -f ~/.maven_env ]; then
    source ~/.maven_env
fi

# 2. 실행 즉시 현재 세션에 반영하는 래퍼 함수
function update-mvn-config() {
    # 스크립트 실행 (환경 파일 ~/.maven_env 생성)
    command update-mvn-config
    
    # 생성된 환경 파일 즉시 로드
    if [ -f ~/.maven_env ]; then
        source ~/.maven_env
        echo "[System] 현재 터미널의 M2_HOME, MAVEN_HOME, PATH가 즉시 갱신되었습니다."
    fi
}
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./update-mvn-config --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./update-mvn-config --target global
```
