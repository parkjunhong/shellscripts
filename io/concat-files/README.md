# 📑 concat-files

복수의 텍스트 또는 데이터 파일을 단일 대상 파일로 순차 병합(Concatenate)하면서, 특정 문자열 패턴이 포함된 라인을 선택적으로 제외(`--remove`)하고 파일별 라인 수 증감 변화를 실시간으로 로깅하는 파일 병합 CLI 도구입니다.

---

## ✨ 주요 특징

1. **다중 소스 파일 순차 병합**
   * `--src` 옵션 뒤에 여러 개의 소스 파일 경로를 나열하여 하나의 대상 파일(`--dst`)로 순차 병합합니다.
2. **조건부 라인 필터링/제외 (`--remove`)**
   * 헤더 라인, 특정 구분자, 주석 등 병합 결과에서 제외하고자 하는 문자열 패턴을 지정하여 깨끗한 데이터셋을 생성합니다.
3. **실시간 행 수(Line Count) 변화 추적**
   * 각 소스 파일을 병합할 때마다 소스 파일의 행 수, 대상 파일의 이전 행 수, 병합 후 행 수를 직관적으로 출력하여 데이터 누락이나 이상 여부를 즉시 검증할 수 있습니다.
4. **지능형 Bash 자동 완성 (`concat-files.completion`)**
   * CLI 옵션 및 소스/대상 파일 경로에 대한 Bash 탭 자동 완성을 지원합니다.

---

## ⚙️ 파라미터 명세

```bash
concat-files --src <소스파일1> [소스파일2...] --dst <대상파일> [옵션...]
```

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--src <file...>` | **필수** | 병합할 하나 이상의 원본 파일 경로 목록 |
| `--dst <file>` | **필수** | 병합 결과가 저장될 대상 파일 경로 |
| `--remove <str>` | 선택 | 병합 시 제외할 문자열 패턴 (해당 문자열을 포함하는 행 제거) |
| `--help` | 선택 | 도움말 메시지 출력 및 종료 |

---

## 🚀 사용 예시

```bash
# 1) 기본 파일 병합
./concat-files --src part1.log part2.log part3.log --dst combined.log

# 2) 주석(#) 라인을 제외하고 설정 파일들 병합
./concat-files --src app_a.conf app_b.conf --dst merged.conf --remove "#"

# 3) 단일 소스 파일에서 특정 불필요 로그 라인을 제거하여 새 파일 생성
./concat-files --src raw_data.csv --dst clean_data.csv --remove "DEBUG"
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./concat-files --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./concat-files --target global
```

