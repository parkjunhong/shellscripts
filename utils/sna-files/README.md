# sna-files

디렉토리 내 특정 확장자 파일들을 탐색하여 지정한 문자열(`-s`)이 누락된 파일들을 식별하고, 파일의 상단(`top`) 또는 하단(`bottom`)에 새로운 내용(문자열 `-c` 또는 파일 `-f`)을 자동으로 추가(Search And Append)하는 파일 배치 수정 도구입니다.

---

## ✨ 주요 특징

- **조건부 내용 주입**: 이미 대상 문자열이 존재하는 파일은 건너뛰고, 누락된 파일에만 선별적으로 내용을 안전하게 추가합니다.
- **상단/하단 위치 선택**: 파일의 맨 앞(`top`, 기본값)에 라이선스나 패키지/임포트 헤더를 추가하거나, 파일의 맨 끝(`bottom`)에 공통 설정을 덧붙일 수 있습니다.
- **다중 탐색 및 제외 디렉토리 지원**: 여러 디렉토리(`-d`)를 동시에 탐색하고, 특정 디렉토리(`-x`)는 탐색에서 제외(`-prune`)할 수 있습니다.
- **직관적인 자동완성**: 디렉토리, 확장자, 파일 및 위치(`top`/`bottom`)에 대한 상황별 Bash 자동완성을 지원합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 단축 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :---: | :--- |
| `--input-dir <디렉토리>` | `-d` | **필수** | - | 검색할 대상 디렉토리 (복수 지정 가능) |
| `--file-ext <확장자>` | `-t` | **필수** | - | 검색할 파일 확장자 (예: `sh`, `java`, `yml`) |
| `--target-str <문자열>` | `-s` | **필수** | - | 존재 여부를 검사할 기준 문자열 |
| `--content-position <위치>` | `-p` | 선택 | `top` | 내용 추가 위치 (`top` 또는 `bottom`) |
| `--content-str <문자열>` | `-c` | 선택* | - | 추가할 문자열 내용 (`-c` 또는 `-f` 중 하나 필수) |
| `--content-file <파일경로>` | `-f` | 선택* | - | 추가할 내용이 담긴 파일 경로 (`-c` 또는 `-f` 중 하나 필수) |
| `--excluded-dir <디렉토리>` | `-x` | 선택 | - | 검색에서 제외할 디렉토리 경로 (복수 지정 가능) |
| `--help` | `-h` | 선택 | - | 도움말 메시지를 표시합니다. |

---

## 🚀 사용 예시

### 1. 셸 스크립트에 라이선스 헤더 일괄 추가 (상단 추가)
```bash
sna-files -d ./scripts -t sh -s "Apache License" -c "# Copyright 2026. All rights reserved." -p top
```

### 2. 제외 디렉토리 지정 및 파일 내용 주입
```bash
sna-files -d /opt/services -t conf -s "MANAGED_BY" -f ./notice.txt -x /opt/services/legacy
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../scriptctl/scriptctl install --script ./sna-files --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../scriptctl/scriptctl install --script ./sna-files --target global
```
