# copy-suffix

파일 복사 시 현재 날짜(YYYYMMDD), 타임스탬프(YYYYMMDDHHMMSS) 또는 사용자 정의 접미사를 파일명의 확장자 앞 또는 뒤에 결합하여 안전하게 스냅샷을 백업하고 복제하는 파일 백업 유틸리티입니다.

---

## ✨ 주요 특징

- **자동 타임스탬프 결합**:
  - `--date`: 현재 날짜(`YYYYMMDD`)를 접미사로 자동 부착 (예: `app.conf` &rarr; `app-20261027.conf`)
  - `--time`: 현재 시각(`YYYYMMDDHHMMSS`)까지 상세 타임스탬프 부착
  - `--suffix`: 사용자가 지정한 임의의 문자열 접미사 부착
- **확장자 위치 제어 (`--ext`)**:
  - 기본: 확장자 앞 결합 (`filename-<suffix>.ext`)
  - `--ext` 지정: 확장자 뒤 결합 (`filename.ext-<suffix>`)
- **출력 디렉토리 자동 생성 (`--output`)**: 백업 파일이 저장될 대상 디렉토리를 지정할 수 있으며 미존재 시 대화형으로 생성합니다.
- **지능형 Bash 자동완성**: 디렉토리 및 파일, 전용 옵션을 자동으로 완성합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `<filename>` | **필수** | - | 백업/복제할 원본 파일 경로 |
| `--date` | 선택 | 기본값 | 현재 날짜(`YYYYMMDD`) 접미사 부착 |
| `--time` | 선택 | - | 현재 날짜 및 시각(`YYYYMMDDHHMMSS`) 접미사 부착 |
| `--suffix <문자열>` | 선택 | - | 사용자가 직접 정의한 접미사 (지정 시 `--date`/`--time` 무시) |
| `--ext` | 선택 | 비활성 | 확장자 뒤에 접미사 부착 (`<name>.<ext>-<suffix>`) |
| `--output <디렉토리>` | 선택 | 동일 경로 | 복사본이 생성될 목적지 디렉토리 경로 |
| `--help` | 선택 | - | 도움말 메시지를 표시합니다. |

---

## 🚀 사용 예시

### 1. 설정 파일에 오늘 날짜를 붙여 복제
```bash
copy-suffix --date ./nginx.conf
# 결과: ./nginx-20261027.conf
```

### 2. 백업 디렉토리에 상세 타임스탬프를 확장자 뒤에 붙여 백업
```bash
copy-suffix --time --ext ./application.yml --output /data/backup
# 결과: /data/backup/application.yml-20261027134500
```

### 3. 사용자 정의 접미사 부착
```bash
copy-suffix --suffix "backup-v1" ./service.sh
# 결과: ./service-backup-v1.sh
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../../utils/scriptctl/scriptctl install --script ./copy-suffix --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../../utils/scriptctl/scriptctl install --script ./copy-suffix --target global
```
