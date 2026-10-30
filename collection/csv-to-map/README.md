# csv-to-map

`csv-to-map`은 CSV 형태의 텍스트 데이터를 읽어, 지정된 컬럼 인덱스를 기반으로 Key-Value 형태의 맵(`.map`) 파일로 변환 및 추출하는 CLI 도구입니다.

---

## ✨ 주요 특징

- **컬럼 인덱스 기반 키-값 매핑**: 0부터 시작하는 인덱스를 지정하여 임의의 컬럼을 Key(`--index-key`)와 Value(`--index-value`)로 유연하게 추출합니다.
- **인용 부호(`Quote`) 지원**: 필드 내 구분자가 포함되어 따옴표로 감싸진 필드도 정확하게 파싱합니다.
- **헤더 건너뛰기 지원**: `--skip` 옵션으로 CSV 첫 번째 행(헤더)을 손쉽게 건너뜁니다.
- **실시간 진행률 표시**: 대용량 CSV 파일 처리 시 읽은 행 수와 경과 시간을 실시간 프로그레스 바로 확인할 수 있습니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 **Long Option** 전용으로 동작하며, Short Option은 지원하지 않습니다.

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :--- | :--- |
| `--file <경로>` (또는 파일명) | **필수** | - | 처리할 대상 CSV 파일 경로 |
| `--delim <구분자>` | **필수** | - | CSV 컬럼 구분자 (예: `,`, `\t`, `\|`) |
| `--index-key <인덱스>` | **필수** | - | Map의 Key로 사용할 컬럼의 0-based 인덱스 |
| `--index-value <인덱스>` | **필수** | - | Map의 Value로 사용할 컬럼의 0-based 인덱스 |
| `--quotechar <문자>` | 선택 | `"` (큰따옴표) | 필드를 감싸는 인용 부호 문자 |
| `--skip` | 선택 | `false` | 첫 번째 행(헤더 라인) 건너뛰기 여부 |
| `--write-count <개수>` | 선택 | `2` | 진행률 표시 및 데이터 기록 갱신 주기 |
| `--verbose` | 선택 | `false` | 상세 에러 및 디버깅 메시지 출력 |
| `--help` | 선택 | - | 도움말 및 사용법 안내 출력 |

---

## 🚀 사용 예시

### 1. 기본 CSV 매핑
CSV 파일에서 0번째 컬럼(ID)을 Key로, 2번째 컬럼(이메일)을 Value로 추출하여 `.map` 파일로 저장합니다:
```bash
csv-to-map --file users.csv --delim "," --index-key 0 --index-value 2
```

### 2. 헤더 행 건너뛰기
첫 행에 컬럼명이 포함된 경우 `--skip` 옵션을 추가합니다:
```bash
csv-to-map --file products.csv --delim "," --index-key 1 --index-value 4 --skip
```

### 3. 탭 구분자 및 커스텀 인용 부호 지정
탭(`\t`)으로 구분된 파일 처리:
```bash
csv-to-map --file data.tsv --delim $'\t' --index-key 0 --index-value 1 --skip
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./csv-to-map --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./csv-to-map --target global
```
