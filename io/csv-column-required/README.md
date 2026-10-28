# 📊 csv-column-required

CSV 데이터셋 전체 또는 일부 행을 전수 스캔하여 각 컬럼별 빈 값(`__EMPTY__`)의 존재 여부를 분석하고, 컬럼별 Nullable(빈 값 허용 여부) 및 필수(Required) 스키마 조건을 동적으로 판별하는 CSV 스키마 분석 CLI 도구입니다.

---

## ✨ 주요 특징

1. **따옴표 내부 구분자 이스케이프 지원 (상태 기계 기반 파서)**
   * 단순 문자열 분할(`IFS=,`) 방식이 아닌, 큰따옴표(`"..."`) 내부에 콤마나 개행 등 구분자가 포함된 복합 CSV 레코드를 정확하게 파싱합니다.
2. **컬럼별 Nullable / Required 비트 플래그 동적 산출**
   * 데이터셋을 순회하며 빈 값이 한 번이라도 등장한 컬럼은 `0`(Nullable / 빈 값 허용)으로, 단 한 번도 빈 값이 없는 컬럼은 `1`(Required / Not-Null 제약조건 충족)로 플래그 배열을 업데이트합니다.
3. **컬럼 수 불일치 에러 행 자동 분리 (`*.validated`)**
   * 기준 컬럼 개수와 맞지 않는 비정상 레코드를 별도의 에러 파일(`$FILE.validated`)로 즉시 분리 저장합니다.
4. **대량 데이터 행 제한 (`--read-count`) 및 진행률 표시**
   * 대규모 CSV 파일의 경우 상위 N개 행만 샘플링하여 빠르게 컬럼 특성을 파악할 수 있으며, 실시간 진행률 및 소요 시간을 보고합니다.
5. **지능형 Bash 자동 완성 (`csv-column-required.completion`)**
   * 옵션 및 파일 경로 자동 완성을 지원합니다.

---

## ⚙️ 파라미터 명세

```bash
csv-column-required --file <CSV파일> --delim <구분자> --count <컬럼개수> [옵션...]
```

| 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--file <file>` | **필수** | - | 분석할 입력 CSV 파일 경로 |
| `--delim <char>` | **필수** | - | 컬럼 구분자 (예: `,`, `\t`, `\|`) |
| `--count <num>` | **필수** | - | 기준 컬럼 개수 (양의 정수) |
| `--empty <str>` | 선택 | `__EMPTY__` | 빈 컬럼 값으로 간주할 식별 문자열 |
| `--quotechar <char>` | 선택 | `"` | 따옴표 이스케이프 문자 |
| `--read-count <num>` | 선택 | `-1` (전체) | 검사할 최대 라인 수 (샘플링 시 유용) |
| `--clmn-names <list>` | 선택 | - | 컬럼 이름 목록 (콤마 구분) |
| `--verbose` | 선택 | 비활성 | 오류 라인 터미널 상세 출력 |
| `--help` | 선택 | - | 도움말 메시지 출력 및 종료 |

---

## 🚀 사용 예시

```bash
# 1) 기본 CSV 컬럼 빈 값 분석 (10개 컬럼 기준)
./csv-column-required --file users.csv --delim "," --count 10

# 2) 컬럼명 지정 및 상위 5,000행 샘플 분석
./csv-column-required \
  --file dataset.csv \
  --delim "," \
  --count 5 \
  --clmn-names "id,name,email,age,created_at" \
  --read-count 5000

# 3) 탭 구분자 TSV 파일 분석
./csv-column-required --file access.tsv --delim $'\t' --count 8 --verbose
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./csv-column-required --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./csv-column-required --target global
```

