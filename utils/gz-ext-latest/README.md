# gz-ext-latest

대상 디렉토리에서 가장 최근에 생성된 `.gz` 압축 파일을 자동으로 찾아 압축을 해제하고, 옵션에 따라 원본 `.gz` 파일들을 백업 디렉토리로 이동하여 정리하는 아카이브 관리 도구입니다.

---

## ✨ 주요 특징

- **최신 gz 파일 자동 감지**: 지정한 디렉토리 내에서 가장 최근 수정된 `.gz` 아카이브 파일을 자동으로 검색합니다.
- **선택적 원본 백업 디렉토리 이동 (`--backup`)**:
  - `--backup` 옵션 미지정 시: 대상 위치에서 `gzip -dfv`로 즉시 압축 해제
  - `--backup <백업경로>` 지정 시: `gunzip --stdout`으로 압축을 해제한 후, 디렉토리 내의 `*.gz` 파일들을 백업 디렉토리로 일괄 이동 정리
- **소요 시간 측정**: 압축 해제 작업에 소요된 시간을 초 단위로 측정하여 출력합니다.
- **지능형 Bash 자동완성**: 디렉토리 경로 및 옵션을 편리하게 자동완성할 수 있습니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `<gz-directory>` | **필수** | - | `.gz` 파일이 위치한 대상 디렉토리 경로 |
| `--backup <백업디렉토리>` | 선택 | - | 압축 해제 후 원본 `.gz` 파일들을 이동시킬 백업 디렉토리 |
| `--help` | 선택 | - | 도움말 메시지를 표시합니다. |

---

## 🚀 사용 예시

### 1. 대상 디렉토리의 최신 gz 파일 압축 해제
```bash
gz-ext-latest /data/logs/archive
```

### 2. 압축 해제 후 원본 gz 파일들을 백업 디렉토리로 이동
```bash
gz-ext-latest --backup /data/logs/backup /data/logs/incoming
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../scriptctl/scriptctl install --script ./gz-ext-latest --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../scriptctl/scriptctl install --script ./gz-ext-latest --target global
```
