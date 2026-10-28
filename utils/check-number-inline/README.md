# check-number-inline

CSV 또는 쉼표(`,`)로 구분된 텍스트 파일에서 지정한 열(column index)의 데이터가 순수 숫자인지 행(line) 단위로 전수 검증하고, 숫자가 아닌 비정상 데이터가 발견된 경우 오류 로그 파일에 기록하는 데이터 무결성 검증 도구입니다.

---

## ✨ 주요 특징

- **특정 컬럼 전수 숫자 검증**: 검증 대상 컬럼 인덱스(0부터 시작하는 숫자)를 복수 개 지정하여 한 행씩 엄격하게 숫자인지 검증합니다.
- **오류 행 자동 격리/기록**: 숫자가 아니거나 형식이 일치하지 않는 행은 `error-<파일명>` 파일에 줄 번호와 함께 즉시 기록합니다.
- **실시간 처리 진행률 표시**: 대용량 파일 검증 시 현재 처리 중인 행 번호와 점 진척도(Dot Progress)를 터미널에 실시간으로 출력합니다.
- **지능형 Bash 자동완성**: 파일 경로 및 옵션을 편리하게 자동완성할 수 있습니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--file <파일경로>` | **필수** | - | 검증할 원본 CSV/텍스트 파일 경로 |
| `<column_index...>` | **필수** | - | 검증할 열 인덱스 (0부터 시작하는 정수, 복수 지정 가능) |
| `--help` | 선택 | - | 도움말 메시지를 표시합니다. |

---

## 🚀 사용 예시

### 1. 0번째 열(첫 번째 열)의 숫자 여부 검증
```bash
check-number-inline --file ./dataset.csv 0
```

### 2. 복수 열(0번째, 3번째, 5번째 열) 동시 검증
```bash
check-number-inline --file ./transactions.csv 0 3 5
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../scriptctl/scriptctl install --script ./check-number-inline --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../scriptctl/scriptctl install --script ./check-number-inline --target global
```
