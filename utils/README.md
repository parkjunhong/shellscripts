# Utility Shell Scripts

시스템 운영, 파일 및 코드 블록 정밀 검색·치환, 데이터 무결성 검증, 원격 접속·전송 스크립트 자동 생성, 스크립트 라이프사이클 관리(`scriptctl`)를 지원하는 표준 CLI 유틸리티 모음입니다.

모든 도구는 독립 실행형 Canonical 디렉토리 구조(`utils/<tool>/<tool>`), 최신 표준 Bash 자동완성(`.completion`), 그리고 상세한 개별 `README.md`를 갖추고 있습니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | Canonical 경로 | 주요 기능 및 특징 | Bash 자동완성 | 개별 문서 |
| :--- | :--- | :--- | :---: | :---: |
| **autotail** | [`autotail/`](autotail/autotail) | 대상 파일 생성 대기(Polling) 후 생성 즉시 `tail -f` 자동 추적 | ✅ 지원 | [상세보기](autotail/README.md) |
| **canonical-status** | [`canonical-status/`](canonical-status/canonical-status) | 하위 디렉토리(depth=1, 2) 내 `README.md` 존재 여부 기반 Canonical 작업 현황 트리 시각화 | ✅ 지원 | [상세보기](canonical-status/README.md) |
| **check-number-inline** | [`check-number-inline/`](check-number-inline/check-number-inline) | CSV/구분자 파일의 특정 열(Index) 데이터가 숫자인지 행별 정밀 검증 및 오류 격리 | ✅ 지원 | [상세보기](check-number-inline/README.md) |
| **csv-count-checker** | [`csv-count-checker/`](csv-count-checker/csv-count-checker) | CSV 파일의 행별 데이터 컬럼(필드) 수 정합성 검증 및 불일치 행 실시간 기록 | ✅ 지원 | [상세보기](csv-count-checker/README.md) |
| **diff-file** | [`diff-file/`](diff-file/diff-file) | 기준 파일과 대상 파일들의 내용 정규화 비교 보고서 생성 및 동기화/Dry-run 지원 | ✅ 지원 | [상세보기](diff-file/README.md) |
| **grep-files** | [`grep-files/`](grep-files/grep-files) | 다중 파일 패턴 대상 고속 문자열/정규식 검색 및 결과 집계 요약 | ✅ 지원 | [상세보기](grep-files/README.md) |
| **gz-ext-latest** | [`gz-ext-latest/`](gz-ext-latest/gz-ext-latest) | 대상 디렉토리의 최신 `.gz` 파일 탐색·압축 해제 및 선택적 백업 디렉토리 이동 | ✅ 지원 | [상세보기](gz-ext-latest/README.md) |
| **modify-enc-str** | [`modify-enc-str/`](modify-enc-str/modify-enc-str) | 암/복호화 스크립트 연동을 통한 설정 파일 내 암호화 문자열 대화형 일괄 치환 | ✅ 지원 | [상세보기](modify-enc-str/README.md) |
| **replace-codeblock** | [`replace-codeblock/`](replace-codeblock/replace-codeblock) | 파일 내 지정한 시작/종료 태그 사이의 코드 블록을 신규 블록으로 정밀 치환 | ✅ 지원 | [상세보기](replace-codeblock/README.md) |
| **replace-files** | [`replace-files/`](replace-files/replace-files) | 다중 파일 패턴 대상 고성능 문자열 일괄 치환 및 자동 백업 관리 | ✅ 지원 | [상세보기](replace-files/README.md) |
| **scp-con-gen** | [`scp-con-gen/`](scp-con-gen/scp-con-gen) | `sshpass` 및 `scp` 기반 원격 파일 전송용 실행 쉘 스크립트 자동 생성 | ✅ 지원 | [상세보기](scp-con-gen/README.md) |
| **scriptctl** | [`scriptctl/`](scriptctl/scriptctl) | 쉘 스크립트 배포, 리눅스 표준 자동완성 등록 및 환경 관리 도구 | ✅ 지원 | [상세보기](scriptctl/README.md) |
| **sna-files** | [`sna-files/`](sna-files/sna-files) | 원본 파일명과 일치하는 파일들을 서브 디렉토리에서 검색 및 동일 여부 분석 | ✅ 지원 | [상세보기](sna-files/README.md) |
| **ssh-con-gen** | [`ssh-con-gen/`](ssh-con-gen/ssh-con-gen) | `sshpass` 및 `ssh` 기반 원격 서버 대화형 자동 접속 쉘 스크립트 생성 | ✅ 지원 | [상세보기](ssh-con-gen/README.md) |
| **uuid-list** | [`uuid-list/`](uuid-list/uuid-list) | `uuidgen` 기반 다량의 고유 UUID(v4) 목록 연속 생성 | ✅ 지원 | [상세보기](uuid-list/README.md) |

> [!NOTE]
> `update-java-home.sh`는 `maven/build-mvn-package` 등 다른 빌드 도구에서 `source`하여 사용하는 공통 환경 모듈로, 독립 실행 CLI 도구 목록에서는 제외하고 모듈 파일로 보존합니다.

---

## 📂 디렉토리 구조

```text
utils/
├── README.md                           # Utils 도구 종합 안내 (본 문서)
├── update-java-home.sh                 # [공통 모듈] JAVA_HOME 및 환경변수 갱신 스크립트
├── autotail/
│   ├── autotail                       # 파일 생성 대기 및 실시간 tail 추적
│   ├── autotail.completion            # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── canonical-status/
│   ├── canonical-status               # Canonical 작업 진행 상태 트리 시각화 도구
│   ├── canonical-status.completion    # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── check-number-inline/
│   ├── check-number-inline            # CSV 열 숫자 데이터 검증 도구
│   ├── check-number-inline.completion # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── csv-count-checker/
│   ├── csv-count-checker              # CSV 컬럼 개수 정합성 검증 도구
│   ├── csv-count-checker.completion   # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── diff-file/
│   ├── diff-file                      # 대형 정밀 파일 비교 및 동기화 도구
│   ├── diff-file.completion           # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── grep-files/
│   ├── grep-files                     # 다중 파일 패턴 문자열 검색 도구
│   ├── grep-files.completion          # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── gz-ext-latest/
│   ├── gz-ext-latest                  # 최신 .gz 파일 압축 해제 및 백업 도구
│   ├── gz-ext-latest.completion       # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── modify-enc-str/
│   ├── modify-enc-str                 # 암호화 문자열 일괄 치환 도구
│   ├── modify-enc-str.completion      # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── replace-codeblock/
│   ├── replace-codeblock              # 태그 기반 코드 블록 치환 도구
│   ├── replace-codeblock.completion   # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── replace-files/
│   ├── replace-files                  # 파일 내 문자열 일괄 치환 도구
│   ├── replace-files.completion       # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── scp-con-gen/
│   ├── scp-con-gen                    # 원격 scp 전송 스크립트 자동 생성 도구
│   ├── scp-con-gen.completion         # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── scriptctl/
│   ├── scriptctl                      # 쉘 스크립트 및 자동완성 설치/관리 도구
│   ├── scriptctl.completion           # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── sna-files/
│   ├── sna-files                      # 동일 파일명 검색 및 분석 도구
│   ├── sna-files.completion           # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── ssh-con-gen/
│   ├── ssh-con-gen                    # 원격 ssh 접속 스크립트 자동 생성 도구
│   ├── ssh-con-gen.completion         # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
└── uuid-list/
    ├── uuid-list                      # 고유 UUID 목록 생성 유틸리티
    ├── uuid-list.completion           # Bash 자동완성 스크립트
    └── README.md                      # 개별 도구 상세 설명서
```

---

## 🛠️ 공통 설치 안내

각 도구는 독립 실행형 CLI 도구로, 본 디렉토리의 `scriptctl` 유틸리티를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로(`/usr/local/bin`)에 간편하게 설치할 수 있습니다. 스크립트 설치 시 연관된 Bash 자동완성 규칙이 시스템 표준 경로(`/usr/share/bash-completion/completions/`)에 자동으로 등록됩니다.

### `scriptctl` 도구를 사용한 설치

```bash
# 개인 환경 설치 예시 (~/bin, 사용자 자동완성 등록)
./scriptctl/scriptctl install --script ./diff-file/diff-file --target local
./scriptctl/scriptctl install --script ./replace-codeblock/replace-codeblock --target local
./scriptctl/scriptctl install --script ./grep-files/grep-files --target local

# 시스템 전역 설치 예시 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
# ※ 주의: scriptctl 자체의 권한 상승 차단을 위해 명령어 앞에 sudo를 붙이지 않습니다.
./scriptctl/scriptctl install --script ./diff-file/diff-file --target global
```
