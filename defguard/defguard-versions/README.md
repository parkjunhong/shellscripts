# defguard-versions

Docker 기반 Defguard VPN 스택(Core, Gateway, Proxy, PostgreSQL)의 컨테이너 실행 상태 및 컴포넌트 버전을 일괄 점검하는 CLI 도구입니다.

## ✨ 주요 특징

- **스택 전체 통합 점검**: `defguard-core`, `defguard-gateway`, `defguard-edge`(Proxy), `postgresql` 4개 구성요소의 상태(`실행 중`, `정지 중`, `미설치`), 컨테이너명, 실행 버전, 이미지 정보를 표 형태로 깔끔하게 출력합니다.
- **정확한 이미지 태그 복원**: `docker container ls` 상에서 이미지가 해시 ID로 표시되는 환경에서도 `.Image` ID의 `RepoTags`를 보조 조회하여 실제 이미지 태그(`ghcr.io/defguard/...`)를 표시합니다.
- **다중 폴백 버전 추출**: 컨테이너 내부 바이너리(`--version`) 실행을 1순위로 시도하고, 미지원 시 OCI 이미지 라벨(`org.opencontainers.image.version`)과 이미지 태그 순으로 버전을 추출합니다.
- **자동화 친화적 JSON 출력**: `--json` 옵션을 통해 CI/CD, 모니터링 스크립트 등에서 바로 파싱할 수 있는 JSON 결과를 제공합니다.
- **상태 알림 가이드**: 정지되거나 미설치된 컨테이너가 감지되면 하단에 조치 안내(`docker start` 등)를 함께 출력합니다.

## ⚙️ 파라미터 명세

| 옵션 | 인자 | 기본값 | 설명 |
| :--- | :--- | :--- | :--- |
| `--core` | `<이름>` | `defguard-core` | Defguard Core 컨테이너 이름 지정 |
| `--gateway` | `<이름>` | `defguard-gateway` | Defguard Gateway 컨테이너 이름 지정 |
| `--proxy` | `<이름>` | `defguard-edge` | Defguard Proxy(Edge) 컨테이너 이름 지정 |
| `--db` | `<이름>` | `postgresql` | PostgreSQL 컨테이너 이름 지정 |
| `--json` | - | `false` | 점검 결과를 JSON 포맷으로 출력 |
| `--verbose` | - | `false` | 내부 바이너리 실행 원본 출력(Raw Output)을 stderr로 함께 출력 |
| `--help` | - | - | 사용법 도움말 출력 후 종료 |

## 🚀 사용 예시

```bash
# 1. 기본 설정으로 Defguard 스택 버전 점검
defguard-versions

# 2. JSON 포맷으로 출력
defguard-versions --json

# 3. 커스텀 컨테이너 이름을 지정하여 점검
defguard-versions --core custom-core --proxy custom-edge --db custom-pg

# 4. 바이너리 원본 출력과 함께 디버그 점검
defguard-versions --verbose
```

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 연관된 Bash 자동완성 스크립트(`.completion`)와 매뉴얼(`man`) 페이지도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 및 ~/.local/share/man 등록) 
../../utils/scriptctl/scriptctl install --script ./defguard-versions --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 및 /usr/local/share/man 등록) 
../../utils/scriptctl/scriptctl install --script ./defguard-versions --target global
```
