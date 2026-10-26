# 🐳 dkcontls

`docker container ls` 명령을 래핑하여 **Long Option 전용 인터페이스**, **콤마(`,`) 기반 다중 출력 컬럼(`--format`) 선택**, 그리고 **필터 속성(`--filter`) 자동 완성**을 제공하는 CLI 유틸리티입니다.

---

## ✨ 주요 특징

1. **`docker container ls`의 모든 옵션 지원 (Short Option 배제)**
   * `--all`, `--filter`, `--format`, `--last`, `--latest`, `--no-trunc`, `--quiet`, `--size`, `--help`를 지원하며 단축 옵션(`-a`, `-f`, `-q` 등)은 허용하지 않습니다.
2. **직관적인 `--format` 컬럼 다중 선택 및 자동 Go 템플릿 변환**
   * 복잡한 Go 템플릿 문법(`table {{.ID}}\t{{.Names}}...`)을 직접 작성할 필요 없이, `[ID|Image|Command|CreatedAT|RunningFor|Ports|State|Status|Names|Size]` 중 원하는 컬럼을 콤마(`,`)로 나열하면 자동으로 테이블 포맷으로 변환합니다.
   * Bash Completion에서 이미 선택한 컬럼은 제외하고 나머지 컬럼만 이어서 추천합니다.
   * 주의: Docker 내부 Go 템플릿 필드명은 `.CreatedAt`이나, 사용자 편의를 위해 `CreatedAT` 입력 시에도 자동으로 `{{.CreatedAt}}`로 매핑됩니다.
3. **`--filter` 속성 및 값 Bash Completion 지원**
   * `id=`, `name=`, `label=`, `exited=`, `status=`, `ancestor=`, `before=`, `since=`, `isolation=`, `volume=`, `network=`, `publish=`, `expose=`, `health=`, `is-task=` 등 15개 표준 필터 속성을 자동 완성합니다.
   * `status=`, `health=`, `is-task=`, `isolation=` 입력 시 허용되는 열거형 값을 추천하며, `name=`, `id=`, `network=`, `volume=`, `ancestor=` 입력 시 현재 시스템의 Docker 리소스 목록을 동적으로 추천합니다.
4. **안전한 권한 제어**
   * 스크립트 자체를 외부에서 `sudo dkcontls ...`로 실행하는 것을 차단하며, 일반 사용자로 Docker 소켓 접근이 불가능한 환경에서만 내부적으로 `sudo` 인증을 요청합니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 복수 지정 | 설명 |
| :--- | :---: | :--- |
| `--all` | 불가 | 모든 상태의 컨테이너 표시 (생략 시 실행 중인 컨테이너만 표시) |
| `--filter <key=value>` | **가능** | 조건 기반 컨테이너 필터링 (`status=running`, `name=web` 등) |
| `--format <columns\|fmt>` | 불가 | 콤마 구분 컬럼 목록(`ID,Names,Status,Ports` 등) 또는 `table`, `json`, Go 템플릿 |
| `--last <int>` | 불가 | 마지막에 생성된 N개의 컨테이너 표시 (모든 상태 포함) |
| `--latest` | 불가 | 가장 최근에 생성된 컨테이너 1개 표시 (모든 상태 포함) |
| `--no-trunc` | 불가 | 출력 내용을 생략(truncate)하지 않고 전체 표시 |
| `--quiet` | 불가 | 컨테이너 ID만 출력 |
| `--size` | 불가 | 컨테이너 총 파일 크기 표시 |
| `--help` | 불가 | 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1) 원하는 컬럼(ID, Names, State, Status, Ports)만 선택하여 테이블로 출력
./dkcontls --format ID,Names,State,Status,Ports

# 2) 모든 컨테이너 중 종료(exited) 상태인 컨테이너의 ID, Image, CreatedAT, Status 조회
./dkcontls --all --filter status=exited --format ID,Image,CreatedAT,Status

# 3) 최근 생성된 5개 컨테이너의 크기 포함 조회
./dkcontls --last 5 --size
```
