# replace-codeblock

Perl의 슬러프(`-0777`) 모드를 활용하여 지정된 디렉토리 하위의 텍스트 파일들에서 다중 행(멀티라인) 코드 블록을 안전하게 일괄 치환하고, 자동 롤백 백업(`.rollback_backup_<TIMESTAMP>`) 및 작업 감사 로그를 생성하는 전문 코드 블록 치환 도구입니다.

---

## ✨ 주요 특징

- **다중 행(Multiline) 코드 블록 치환**: 단일 행 치환 도구로 처리하기 어려운 여러 줄에 걸친 함수, 블록, 설정 스니펫을 원본 그대로 안전하게 치환합니다.
- **안전한 자동 백업 및 롤백 지원**: 수정되는 모든 파일은 수정 직전 전용 백업 폴더(`.rollback_backup_<TIMESTAMP>/`)에 자동 보관됩니다.
- **시뮬레이션(`--dry-run`) 모드**: 실제 파일 변경 없이 매칭되는 파일과 치환 대상 파일 목록을 사전 검증할 수 있습니다.
- **실시간 프로그레스 표시 및 상세 로깅**: 터미널 너비에 맞춘 동적 진행률 바를 지원하며, 작업 완료 후 치환 결과(`replace-codeblock-<target>.log`)를 파일로 남깁니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--target-dir <경로>` | **필수** | 대상 파일들을 탐색할 루트 디렉토리 |
| `--target-name <파일명>` | **필수** | 변경할 대상 파일명 (예: `deploy.sh`, `application.yml`) |
| `--before <파일경로>` | **필수** | 치환 대상이 될 기존 원본 코드 블록이 담긴 파일 |
| `--after <파일경로>` | **필수** | 교체하여 삽입할 새 코드 블록이 담긴 파일 |
| `--dry-run` | 선택 | 실제 파일 수정 없이 변경될 파일 목록만 시뮬레이션 |
| `-h, --help` | 선택 | 도움말 메시지를 출력합니다. |

---

## 🚀 사용 예시

### 1. 다중 프로젝트의 deploy.sh 내 특정 코드 블록 치환
```bash
replace-codeblock \
  --target-dir /opt/services \
  --target-name deploy.sh \
  --before ./old_block.txt \
  --after ./new_block.txt
```

### 2. 가상 시뮬레이션(Dry-run) 실행
```bash
replace-codeblock \
  --target-dir ./projects \
  --target-name "pom.xml" \
  --before ./old_plugin.xml \
  --after ./new_plugin.xml \
  --dry-run
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../scriptctl/scriptctl install --script ./replace-codeblock --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../scriptctl/scriptctl install --script ./replace-codeblock --target global
```
