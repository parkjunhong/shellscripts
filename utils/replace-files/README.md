# ✏️ replace-files

지정된 디렉토리 하위의 텍스트 파일들에서 특정 리터럴 문자열(`--from`)을 찾아 새로운 문자열(`--to`)로 **안전하게 일괄 치환(또는 삭제)**하고, 백업(`.bak`) 및 변경 감사 로그(`plain` / `json`)를 생성하는 CLI 도구입니다.

*(기존 `string/replace-text.sh`의 구조적 버그 8종을 수정하고 `utils/replace-files/`로 리팩토링 및 이동)*

---

## ✨ 주요 개선 및 버그 수정 내역

1. **파이프라인 서브셸(Subshell) 변수 증발 버그 수정**
   * 기존 `find ... | while read file` 구조에서는 서브셸에서 루프가 실행되어 `--summary` 통계(`count_total`, `count_modified`, `count_backup`)와 `--log-output` 로그 변수가 루프 종료 시 모두 `0` 및 빈 값으로 초기화되던 치명적 버그를 프로세스 치환(`done 3< <(find ...)`)으로 해결했습니다.
2. **사용자 확인(`--confirm`) 시 `stdin` 충돌 해결**
   * `find` 스트림과 `read -rp` 키보드 입력이 같은 `stdin`(FD 0)을 공유하여 파일 경로를 삼켜버리던 문제를 별도 파일 디스크립터(FD 3) 분리 및 `</dev/tty` 명시로 해결했습니다.
3. **빈 문자열 치환(문자열 삭제) 정상 지원**
   * 기존에는 `[[ -z "$replacement" ]]`일 때 필수 인자 누락 에러가 발생하여 빈 문자열로 삭제할 수 없던 문제를 옵션 전달 여부(`has_to`) 체크로 수정하여 `--to ""` 삭제를 완벽히 지원합니다.
4. **치환 전 로그 캡처 순서 바로잡기**
   * 기존에는 `sed -i`로 문자열을 먼저 바꾼 뒤에 `grep`으로 로그를 수집하여 실제 변경 시 로그가 비어버리던 순서 역전 버그를 수정했습니다.
5. **정규식 메타문자 안전 이스케이프 및 바이너리/백업 파일 보호**
   * `.` `*` `[` `]` `^` `$` `/` `&` 등 모든 BRE 메타문자를 안전하게 이스케이프하여 리터럴 문자열을 정확히 치환하며, 바이너리 파일(`grep -I`), `.git` 폴더, `.bak` 백업 파일은 치환 대상에서 자동 제외합니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 기본값 | 복수 지정 | 설명 |
| :--- | :---: | :---: | :---: | :--- |
| `--from <STRING>` | **필수** | - | 불가 | 검색할 원본 리터럴 문자열 |
| `--to <STRING>` | **필수** | - | 불가 | 치환할 결과 리터럴 문자열 (빈 문자열 `""` 입력 시 검색 문자열 삭제) |
| `--dir <DIR>` | 선택 | 현재 디렉토리(`$PWD`) | **가능** | 검색 시작 디렉토리 |
| `--exclude-dir <DIR>` | 선택 | `.git` 기본 제외 | **가능** | 제외할 디렉토리 경로 또는 폴더명 |
| `--ext <EXT1[,EXT2...]>` | 선택 | 전체 텍스트 파일 | **가능** | 파일 확장자 필터 (대소문자 무시, 예: `sh,conf,xml`) |
| `--filename <RULE>` | 선택 | - | **가능** | 파일명 매칭 규칙 (`^접두어`, `접미어$`, `포함문자열`) |
| `--backup` | 선택 | `false` | 불가 | 치환 전 원본 파일을 `<파일명>.bak`으로 백업 |
| `--confirm` | 선택 | `false` | 불가 | 각 파일 치환 전 사용자에게 실행 여부(`y/N`) 확인 |
| `--dry-run` | 선택 | `false` | 불가 | 실제 변경 없이 매칭 파일 및 라인만 시뮬레이션 출력 |
| `--summary` | 선택 | `false` | 불가 | 작업 완료 후 상세 요약 통계 박스 출력 |
| `--log-output <FILE>` | 선택 | - | 불가 | 치환 내역 로그를 지정한 파일에 저장 |
| `--log-format <plain\|json>` | 선택 | `plain` | 불가 | 로그 파일 저장 형식 (`plain` 또는 `json`) |
| `--help` | 선택 | - | 불가 | 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1) 시뮬레이션(--dry-run)으로 변경될 파일과 줄 번호/내용 미리 확인
./replace-files --dir ./config --ext conf,properties \
                --from "localhost:8080" --to "10.0.0.10:8080" \
                --dry-run --summary

# 2) 백업(.bak) 생성과 함께 실제 치환 및 JSON 감사 로그 기록
./replace-files --dir ./src --ext java \
                --from "oldMethodName" --to "newMethodName" \
                --backup --summary --log-output audit.json --log-format json

# 3) 파일 내 특정 문자열 일괄 삭제 (--to "")
./replace-files --dir ./scripts --ext sh \
                --from "DEPRECATED_OPTION" --to "" --confirm
```
