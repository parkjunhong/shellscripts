# match-error-lnb

`match-error-lnb`는 Oracle SQL*Loader 실행 로그를 실시간으로 파싱하여 거부된 레코드(Rejected Error)의 원본 데이터 위치와 badfile의 라인 번호를 1:1로 매핑해 주는 로그 분석 CLI 도구입니다.

---

## ✨ 주요 특징

- **SQL*Loader 거부 레코드 정밀 분석**: `Record <num>: Rejected - Error on table <table>, column <column>` 패턴을 정규식으로 감지하여 에러 정보를 추출합니다.
- **원본 데이터 및 Badfile 위치 매핑**: 원본 입력 데이터에서의 행 번호와 SQL*Loader가 생성한 badfile에서의 실제 라인 번호를 매핑하여 기록합니다.
- **실시간 프로그레스 바**: 대용량 로그 파일 분석 시 읽은 라인 수와 처리 진행 상태를 실시간으로 표시합니다.
- **수행 시간 정밀 측정**: 분석 시작/종료 시각 및 총 소요 시간을 시/분/초 형식으로 요약 출력합니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 **Long Option** 전용으로 동작하며, Short Option은 지원하지 않습니다.

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :--- | :--- |
| `--file <파일경로>` (또는 첫 번째 인자) | **필수** | - | 분석할 Oracle SQL*Loader 로그 파일 경로 |
| `--output <파일경로>` | 선택 | `match-badfile-<filename>.txt` | 매핑 결과를 저장할 출력 파일 경로 |
| `--help` | 선택 | - | 도움말 및 옵션 안내 출력 |

---

## 🚀 사용 예시

### 1. 기본 분석 실행
```bash
match-error-lnb --file sqlldr_import.log
```
결과는 `match-badfile-sqlldr_import.log.txt` 파일에 저장됩니다.

### 2. 출력 파일명 직접 지정
```bash
match-error-lnb --file sqlldr_import.log --output errors_mapping.txt
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./match-error-lnb --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./match-error-lnb --target global
```
