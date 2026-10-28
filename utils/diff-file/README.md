# diff-file

기준 파일(`--source`)과 대상 디렉토리 하위의 검색 패턴(`--file`)에 일치하는 파일들의 내용을 정규화 비교하여 일치/불일치 상세 보고서를 생성하고, 옵션에 따라 내용을 동기화(`--copy-content`)하거나 가상 검증(`--dry-run`)을 수행하는 대형 정밀 파일 비교 도구입니다.

---

## ✨ 주요 특징

- **정규화 비교 엔진**: 공백 및 줄바꿈 차이를 안전하게 정규화하여 실제 내용의 일치 여부를 정확히 판별합니다.
- **다양한 실행 모드 지원**:
  - 기본 모드: 비교 결과 요약 통계 및 불일치 파일 목록 출력
  - `--copy-content`: 내용이 다른 대상 파일을 기준 파일 내용으로 자동 동기화/덮어쓰기
  - `--dry-run`: 실제 파일 수정 없이 변경 예정 파일 및 작업 흐름 시뮬레이션
  - `--no-ne-files`: 불일치 파일 목록 출력을 생략하고 요약 통계만 표시
- **임시 리소스 격리 및 정리**: 임시 디렉토리를 생성하여 안전하게 정규화 작업을 수행하며 `cleanup` 트랩을 통해 종료 시 완벽히 제거합니다.
- **지능형 Bash 자동완성**: 디렉토리, 파일 및 전용 옵션들을 스마트하게 추천합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--source <파일>` | **필수** | - | 비교 기준이 되는 원본 파일 경로 |
| `--file <패턴>` | **필수** | - | 검색할 대상 파일명 또는 패턴 (예: `*.yml`, `application-*`) |
| `--directory <디렉토리>` | 선택 | `.` (현재 디렉토리) | 비교 대상을 탐색할 기준 디렉토리 |
| `--copy-content` | 선택 | 비활성 | 내용이 다른 대상 파일의 내용을 기준 파일 내용으로 덮어씁니다. |
| `--no-ne-files` | 선택 | 비활성 | 동일하지 않은 파일 목록 출력을 보고서에서 제외합니다. |
| `--dry-run` | 선택 | 비활성 | 실제 비교 및 파일 복사 과정을 가상으로 시뮬레이션합니다. |
| `--help` | 선택 | - | 도움말 메시지를 표시합니다. |

---

## 🚀 사용 예시

### 1. 기준 설정 파일과 하위 설정 파일 비교
```bash
diff-file --source ./config-template.yml --file "config.yml" --directory /opt/services
```

### 2. 가상 시뮬레이션(Dry-run) 실행
```bash
diff-file --source ./standard-env.sh --file "env.sh" --directory . --copy-content --dry-run
```

### 3. 내용이 다른 파일들을 기준 파일로 일괄 동기화
```bash
diff-file --source ./standard-env.sh --file "env.sh" --directory /data/projects --copy-content
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../scriptctl/scriptctl install --script ./diff-file --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../scriptctl/scriptctl install --script ./diff-file --target global
```
