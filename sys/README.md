# System Engineering & Administration Shell Scripts

리눅스 시스템 종합 정보 수집, 디스크 사용량 초고속 분석(`disk-size`), 파일 복사/접미사 백업(`copy-suffix`), 정규식 기반 파일명 일괄 변경(`ren-files`), 명령어 소스 조회 및 지능형 편집(`cat-cli`, `vim-cli`), 그리고 서비스 라이프사이클 완전 삭제(`remove-service`)를 지원하는 표준 CLI 시스템 관리 도구 모음입니다.

모든 도구는 독립 실행형 Canonical 디렉토리 구조(`sys/<tool>/<tool>`), 최신 표준 Bash 자동완성(`.completion`), 그리고 상세한 개별 `README.md`를 갖추고 있습니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | Canonical 경로 | 주요 기능 및 특징 | Bash 자동완성 | 개별 문서 |
| :--- | :--- | :--- | :---: | :---: |
| **cat-cli** | [`cat-cli/`](cat-cli/cat-cli) | PATH에 등록된 명령어의 실제 실행 파일 소스를 찾아 `cat`으로 내용 출력 | ✅ 지원 | [상세보기](cat-cli/README.md) |
| **copy-suffix** | [`copy-suffix/`](copy-suffix/copy-suffix) | 날짜(`-d`), 시각(`-t`) 또는 사용자 접미사를 파일명 앞/뒤에 결합하여 스냅샷 백업 | ✅ 지원 | [상세보기](copy-suffix/README.md) |
| **disk-size** | [`disk-size/`](disk-size/disk-size) | 디렉토리 및 파일 점유 용량 고속 배치 측정, 용량별 정렬(`-sa`, `-sd`), 재귀 탐색 | ✅ 지원 (성능 최적화) | [상세보기](disk-size/README.md) |
| **remove-service** | [`remove-service/`](remove-service/remove-service) | systemd/sysvinit 서비스 중지, 비활성화, 유닛 파일 삭제 및 데몬 상태 완전 초기화 | ✅ 지원 | [상세보기](remove-service/README.md) |
| **ren-files** | [`ren-files/`](ren-files/ren-files) | `sed` 확장 정규표현식(ERE) 그룹 캡처 및 후방 참조를 통한 파일명 일괄 변경 | ✅ 지원 | [상세보기](ren-files/README.md) |
| **sys-info** | [`sys-info/`](sys-info/sys-info) | 호스트, CPU, 메모리 요약 및 디스크 사용량 필터링·정렬 표 대시보드 출력 | ✅ 지원 | [상세보기](sys-info/README.md) |
| **vim-cli** | [`vim-cli/`](vim-cli/vim-cli) | 명령어 이름을 기반으로 실행 파일을 열고, 권한 부족 시 `sudo vim`으로 자동 승격 | ✅ 지원 | [상세보기](vim-cli/README.md) |

---

## 📂 디렉토리 구조

```text
sys/
├── README.md                           # Sys 도구 종합 안내 (본 문서)
├── cat-cli/
│   ├── cat-cli                        # 명령어 소스 조회 도구
│   ├── cat-cli.completion             # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── copy-suffix/
│   ├── copy-suffix                    # 타임스탬프 기반 파일 복사/백업 도구
│   ├── copy-suffix.completion         # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── disk-size/
│   ├── disk-size                      # 고성능 디스크 점유 용량 분석 도구
│   ├── disk-size.completion           # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── remove-service/
│   ├── remove-service                 # 시스템 서비스 완전 삭제 도구
│   ├── remove-service.completion      # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── ren-files/
│   ├── ren-files                      # 정규식 기반 파일명 일괄 변경 도구
│   ├── ren-files.completion           # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── sys-info/
│   ├── sys-info                       # 시스템 및 디스크 종합 진단 도구
│   ├── sys-info.completion            # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
└── vim-cli/
    ├── vim-cli                        # 지능형 명령어 에디터 실행 도구
    ├── vim-cli.completion             # Bash 자동완성 스크립트
    └── README.md                      # 개별 도구 상세 설명서
```

---

## 🛠️ 공통 설치 안내

각 도구는 독립 실행형 CLI 도구로, 저장소의 `utils/scriptctl` 유틸리티를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로(`/usr/local/bin`)에 간편하게 설치할 수 있습니다. 스크립트 설치 시 연관된 Bash 자동완성 규칙이 시스템 표준 경로(`/usr/share/bash-completion/completions/`)에 자동으로 등록됩니다.

### `scriptctl` 도구를 사용한 설치

```bash
# 개인 환경 설치 예시 (~/bin, 사용자 자동완성 등록)
../utils/scriptctl/scriptctl install --script ./disk-size/disk-size --target local
../utils/scriptctl/scriptctl install --script ./sys-info/sys-info --target local
../utils/scriptctl/scriptctl install --script ./remove-service/remove-service --target local

# 시스템 전역 설치 예시 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
# ※ 주의: scriptctl 자체의 권한 상승 차단을 위해 명령어 앞에 sudo를 붙이지 않습니다.
../utils/scriptctl/scriptctl install --script ./disk-size/disk-size --target global
```
