# sys-info

호스트 및 운영체제 정보, CPU 스펙, 상세 메모리 구조, 그리고 디스크 파일시스템별 사용량을 수집하고 정렬 및 필터링하여 일목요연하게 표시하는 시스템 종합 진단 도구입니다.

---

## ✨ 주요 특징

- **종합 시스템 상태 수집**:
  - 호스트 정보: 호스트명(Static Hostname), OS 명칭, 시스템 아키텍처
  - CPU 정보: 소켓 수, 코어 수, 스레드 수, 총 vCPU, CPU 모델명
  - 메모리 정보: Total, Usage, Shared, Free, Buffer/Cache, Available 메모리 실시간 측정
- **디스크 사용량 정밀 테이블 출력**:
  - Filesystem, Size, Used, Avail, Use%, Mounted on 상세 출력
  - 특정 파일시스템 제외 필터링 (`--exclude-fs`)
  - 특정 마운트 경로 제외 필터링 (`--exclude-mnt`)
  - 파일시스템(`fs`) 또는 마운트 경로(`mnt`) 기준 오름차순/내림차순 정렬 지원
- **지능형 Bash 자동완성**: 마운트 지점 및 파일시스템 이름, 정렬 옵션을 실시간으로 감지하여 자동완성합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--exclude-fs <문자열>` | 선택 | - | Filesystem 컬럼에서 제외할 문자열 (다중 지정 가능) |
| `--exclude-mnt <문자열>` | 선택 | - | Mounted on 컬럼에서 제외할 문자열 (다중 지정 가능) |
| `--sort-key <fs\|mnt>` | 선택 | - | 디스크 정렬 기준 (`fs`: 파일시스템, `mnt`: 마운트 지점) |
| `--sort-dir <asc\|desc>` | 선택 | `asc` | 정렬 방향 (`asc`: 오름차순, `desc`: 내림차순) |
| `--help` | 선택 | - | 도움말 메시지를 표시합니다. |

---

## 🚀 사용 예시

### 1. 기본 시스템 및 디스크 종합 진단
```bash
sys-info
```

### 2. 가상 파일시스템(tmpfs, overlay)을 제외하고 마운트 지점 기준 내림차순 정렬
```bash
sys-info --exclude-fs tmpfs --exclude-fs overlay --sort-key mnt --sort-dir desc
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../../utils/scriptctl/scriptctl install --script ./sys-info --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../../utils/scriptctl/scriptctl install --script ./sys-info --target global
```
