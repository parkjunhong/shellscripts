# ✅ validate-csv

CSV 데이터 파일 내 모든 레코드의 컬럼 개수가 규격과 일치하는지 전수 검증하고, 따옴표(`"..."`) 내부의 구분자를 완벽히 보호하며 컬럼 누락 또는 초과가 발생한 불량 행을 에러 로그 파일로 안전하게 분리하는 CSV 무결성 검증 CLI 도구입니다.

---

## ✨ 주요 특징

1. **따옴표 내부 콤마 이스케이프 완벽 지원**
   * 주소, 본문, JSON 등 컬럼 내부에 큰따옴표로 감싸진 콤마(`,`)나 특수문자가 포함된 경우에도 잘못된 컬럼 분리 없이 규격대로 정확하게 파싱합니다.
2. **불량 레코드 자동 분리 격리 (`*.validated`)**
   * 기준 컬럼 수(`--count`)와 일치하지 않는 깨진 라인 번호와 원본 행 데이터를 `$FILE.validated` 파일에 별도로 기록하여 원인 분석을 용이하게 합니다.
3. **실시간 검증 진행률 및 처리 통계 보고**
   * 대용량 CSV 파일 검증 시 현재까지 검사한 행 수, 감지된 오류 건수, 점(dot) 프로그레스 및 총 처리 소요 시간(h/m/s)을 실시간으로 출력합니다.
4. **유연한 커스텀 구분자 및 따옴표 지정**
   * 콤마(`,`)뿐만 아니라 탭(`\t`), 파이프(`|`), 세미콜론(`;`) 등 다양한 텍스트 구분자 규격을 자유롭게 지정할 수 있습니다.
5. **지능형 Bash 자동 완성 (`validate-csv.completion`)**
   * 옵션 및 파일 경로 자동 완성을 제공합니다.

---

## ⚙️ 파라미터 명세

```bash
validate-csv --file <CSV파일> --delim <구분자> --count <기준컬럼개수> [옵션...]
```

| 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--file <file>` | **필수** | - | 검증할 대상 CSV 파일 경로 |
| `--delim <char>` | **필수** | - | 컬럼 구분자 (예: `,`, `\t`, `\|`) |
| `--count <num>` | **필수** | - | 각 레코드가 가져야 하는 정확한 컬럼 개수 |
| `--quotechar <char>` | 선택 | `"` | 따옴표 이스케이프 문자 |
| `--empty <str>` | 선택 | `__EMPTY__` | 빈 컬럼 식별용 대체 문자열 |
| `--verbose` | 선택 | 비활성 | 오류 발생 라인을 터미널에 실시간 출력 |
| `--help` | 선택 | - | 도움말 메시지 출력 및 종료 |

---

## 🚀 사용 예시

```bash
# 1) 기본 5개 컬럼 CSV 파일 정합성 검증
./validate-csv --file customers.csv --delim "," --count 5

# 2) 파이프(|) 구분자 데이터 검증 및 실시간 오류 라인 출력
./validate-csv --file dump.dat --delim "|" --count 12 --verbose

# 3) 검증 실패 시 생성된 에러 로그 파일 확인
cat customers.csv.validated
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./validate-csv --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./validate-csv --target global
```

