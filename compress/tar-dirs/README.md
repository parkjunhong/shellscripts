# tar-dirs

`tar-dirs`는 지정한 대상 디렉토리 내의 하위 디렉토리들을 탐색하여 각각 개별적인 `.tar.gz` 압축 파일로 일괄 아카이빙하는 CLI 도구입니다.

---

## ✨ 주요 특징

- **개별 디렉토리 압축**: 대상 디렉토리 내부의 각 하위 디렉토리를 개별 파일 단위로 자동 압축합니다.
- **포함/제외 패턴 필터링**: `--include` 및 `--exclude` 옵션을 통해 압축할 디렉토리 패턴을 쉼표(`,`) 단위로 지정할 수 있습니다.
- **Dry-run 시뮬레이션 지원**: `--dry-run` 옵션을 통해 실제 압축을 수행하기 전 어떤 디렉토리가 어떻게 압축되는지 안전하게 미리 확인할 수 있습니다.
- **유연한 출력 위치 및 접미사 지정**: 원본 디렉토리와 다른 출력 경로(`--output`)를 지정하거나 아카이브 파일명에 접미사(`--suffix`)를 추가할 수 있습니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 **Long Option** 전용으로 동작하며, Short Option은 지원하지 않습니다.

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :--- | :--- |
| `--target <경로>` | **필수** | - | 하위 디렉토리를 탐색할 대상 디렉토리 경로 |
| `--output <경로>` | 선택 | `--target`과 동일 | 압축 파일들이 생성될 출력 디렉토리 경로 (존재하지 않으면 자동 생성) |
| `--suffix <접미사>` | 선택 | 없음 | 압축 파일명 뒤에 붙일 추가 접미사 (예: `--suffix 20261030`) |
| `--include <패턴>` | 선택 | 없음 | 압축에 포함할 디렉토리 이름 정규식 패턴 (쉼표 구분) |
| `--exclude <패턴>` | 선택 | 없음 | 압축에서 제외할 디렉토리 이름 정규식 패턴 (쉼표 구분) |
| `--dry-run` | 선택 | `false` | 실제 아카이빙을 수행하지 않고 대상 확인 및 명령어 로그만 출력 |
| `--quiet` | 선택 | `false` | 아카이빙 진행 로그를 출력하지 않음 |
| `--help` | 선택 | - | 사용법 및 도움말 메시지 출력 |

---

## 🚀 사용 예시

### 1. 기본 일괄 압축
특정 디렉토리 하위의 모든 디렉토리를 각각 동일 위치에 `.tar.gz`로 압축합니다:
```bash
tar-dirs --target ./projects
```

### 2. 출력 디렉토리 및 접미사 지정
`/backup` 디렉토리에 날짜 접미사를 붙여 압축 파일을 생성합니다:
```bash
tar-dirs --target ./projects --output /backup --suffix 20261030
```

### 3. 특정 패턴 포함 및 제외 필터링
`api` 또는 `web` 디렉토리만 포함하고, `test` 디렉토리는 제외하여 압축합니다:
```bash
tar-dirs --target ./services --include "api,web" --exclude "test"
```

### 4. Dry-run 사전 검증
실제 압축 전에 실행될 명령어를 미리 확인합니다:
```bash
tar-dirs --target ./data --dry-run
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./tar-dirs --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./tar-dirs --target global
```
