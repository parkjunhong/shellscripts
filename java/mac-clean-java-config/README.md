# mac-clean-java-config

`mac-clean-java-config`는 macOS 환경에서 `~/.jenv/versions` 디렉토리를 탐색하여 대상 JDK가 제거되거나 이동되어 깨진 심볼릭 링크(Dangling/Broken Symlinks)를 찾아내고, 사용자의 확인을 거쳐 안전하게 일괄 삭제 및 정리해 주는 CLI 도구입니다.

---

## ✨ 주요 특징

- **깨진 심볼릭 링크 자동 감지**: `~/.jenv/versions` 내에서 링크 대상 경로가 실제로 존재하지 않는 링크를 탐색합니다.
- **삭제 대상 시각화**: 삭제하기 전 깨진 링크의 이름과 원본 연결 경로를 화면에 출력합니다.
- **안전한 확인 절차**: 사용자의 명시적 동의(`y/n`)를 확인한 후에만 삭제를 수행하여 실수를 방지합니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 대화형(Interactive) 실행을 기본으로 하며, **Long Option** 전용으로 동작합니다.

| 파라미터 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--help` | 선택 | 사용법 및 도움말 안내 출력 |

---

## 🚀 사용 예시

### 기본 대화형 정리
```bash
mac-clean-java-config
```
깨진 링크 목록이 발견되면 `y`를 입력하여 안전하게 삭제합니다.

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./mac-clean-java-config --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./mac-clean-java-config --target global
```
