# 🔎 grep-files

지정된 디렉토리(복수 지원)에서 파일들을 대상으로 특정 문자열(`--pattern`)이 **포함된 파일(`match`)** 또는 **누락된 파일(`missing`)**을 스캔하여 **디렉토리·서브디렉토리별 건수 통계 및 매칭 줄 번호·내용(`grep -rn` 형식) 리포트**를 생성하는 CLI 도구입니다.

---

## ✨ 주요 특징

1. **확장자(`--ext`) 선택화 및 다중 확장자 지원**
   * `--ext`를 생략하면 확장자에 구애받지 않고 **모든 텍스트 파일**을 대상으로 검색합니다 (`.git` 디렉토리 및 바이너리 파일 자동 제외).
   * `--ext sh,completion,properties`처럼 콤마(`,`)로 구분하거나 `--ext`를 여러 번 지정하여 복수 확장자를 한 번에 검색할 수 있습니다.
2. **검사 모수(Scanned Count) 및 매칭 통계 동시 제공**
   * 전체 검사 대상 파일 수(`total_scanned`) 대비 매칭된 파일 수(`total_count`)를 디렉토리별로 함께 출력하여 검색 범위를 명확히 파악할 수 있습니다.
3. **`grep -rn` 스타일 줄 번호 및 매칭 내용 출력 (`match` 모드)**
   * `📋 검색된 파일 목록 및 매칭 내용` 섹션에서 각 파일 경로 하단에 매칭된 줄 번호(`[L줄번호]`)와 해당 줄의 내용을 함께 출력합니다.
4. **안전한 배열 기반 실행 (`eval` 제거)**
   * 공백이나 특수문자가 포함된 경로에서도 단어 분리(Word Splitting) 없이 안전하게 동작합니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 기본값 | 복수 지정 | 설명 |
| :--- | :---: | :---: | :---: | :--- |
| `--pattern <STRING>` | **필수** | - | 불가 | 파일 내부에서 찾을 문자열 |
| `--ext <EXT1[,EXT2...]>` | 선택 | 전체 텍스트 파일(`*`) | **가능** | 검색할 파일 확장자 (콤마 구분 가능, 대소문자 무시) |
| `--dir <DIR>` | 선택 | 현재 디렉토리(`$PWD`) | **가능** | 검색 대상 디렉토리 경로 |
| `--exclude-dir <DIR>` | 선택 | `.git` 기본 제외 | **가능** | 검색에서 제외할 디렉토리 경로 또는 폴더명 |
| `--mode <match\|missing>` | 선택 | `match` | 불가 | `match`(문자열 포함 파일+줄 내용) 또는 `missing`(문자열 누락 파일) |
| `--ignore-case` | 선택 | `false` | 불가 | 찾을 문자열(`--pattern`)의 대소문자 무시 |
| `--output <FILE>` | 선택 | 화면 출력 | 불가 | 결과 리포트를 지정한 파일로 저장 |
| `--help` | 선택 | - | 불가 | 도움말 출력 |

---

## 🚀 사용 예시

### 1. 확장자 제한 없이 모든 텍스트 파일에서 문자열 검색 (줄 번호 및 내용 포함)
```bash
./grep-files --pattern searching-word --dir ../../
```

### 2. 복수 확장자(`sh,completion,properties`)를 지정하여 검색
```bash
./grep-files --ext sh,completion,properties --pattern searching-word --dir ../../
```

### 3. 특정 어노테이션(`@NullMarked`)이 누락된(`.java`) 파일 감사 리포트 출력
```bash
./grep-files --dir /path/to/project/src --ext java --pattern "@NullMarked" --mode missing
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../scriptctl/scriptctl install --script ./grep-files --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
sudo ../scriptctl/scriptctl install --script ./grep-files --target global
```

