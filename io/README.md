# 📥 IO (Input / Output & Data Processing Scripts)

대용량 텍스트 파일 병합, 특정 행 범위 슬라이싱, CSV 데이터 무결성 검증 및 컬럼별 Nullable 스키마 분석을 지원하는 파일 입출력 및 데이터 처리 유틸리티 스크립트 모음입니다.

---

## 📂 도구 목록 및 디렉토리 구조

모든 도구는 표준 **Canonical Directory** 구조로 배치되어 있으며, 각 디렉토리 내에 독립 실행 스크립트, Bash 자동 완성(`.completion`), 상세 `README.md`를 포함합니다.

| 도구 이름 (Canonical Name) | 주요 역할 및 설명 | 바로가기 |
| :--- | :--- | :---: |
| **`validate-csv`** | 따옴표 이스케이프 고려 CSV 컬럼 수 정합성 전수 검증 및 불량 레코드 격리 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/io/validate-csv/README.md) |
| **`csv-column-required`** | CSV 컬럼별 빈 값(empty/null) 허용 여부 분석 및 Required 제약조건 판별 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/io/csv-column-required/README.md) |
| **`concat-files`** | 여러 파일을 단일 파일로 순차 병합하며 특정 문자열 라인 필터링 및 행 수 추적 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/io/concat-files/README.md) |
| **`cplines`** | 파일의 N번째 행부터 M개 행을 지정 추출 복사하며 진행률 및 소요시간 통계 출력 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/io/cplines/README.md) |

---

## 🛠️ 공통 설치 안내

각 도구는 독립 실행형 CLI 도구로, 개인 실행 경로(`~/bin` 또는 `~/.local/bin`) 또는 전역 경로(`/usr/local/bin`)에 설치하여 바로 사용할 수 있습니다.

### `scriptctl` 도구를 사용한 간편 설치
저장소의 `utils/scriptctl` 유틸리티를 사용하면 스크립트와 Bash 자동 완성을 시스템에 한 번에 설치할 수 있습니다:

```bash
# 예: validate-csv 설치 (개인 환경: ~/bin)
../utils/scriptctl/scriptctl install --script ./validate-csv/validate-csv --target local

# 예: concat-files 설치
../utils/scriptctl/scriptctl install --script ./concat-files/concat-files --target local
```
