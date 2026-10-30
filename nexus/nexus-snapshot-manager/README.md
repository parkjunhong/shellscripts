# nexus-snapshot-manager

`nexus-snapshot-manager`는 Sonatype Nexus Repository 내 Maven 스냅샷 저장소(`maven-snapshots`)를 대상으로 오래되었거나 불필요한 SNAPSHOT 아티팩트들을 대화형(Interactive) 또는 CLI 인자 기반으로 탐색하고, 버전별 보관 개수 설정에 따라 안전하게 선별 삭제하여 저장 공간을 확보하는 관리 CLI 도구입니다.

---

## ✨ 주요 특징

- **대화형(Interactive) & 비대화형 모드 지원**:
  - 인자 없이 실행 시 그룹 ID 및 아티팩트 ID를 대화형 목록에서 번호로 선택할 수 있습니다.
  - `--group-id` 및 `--artifact-id` 옵션을 통해 콤마(`,`) 구분으로 특정 대상들을 직접 지정할 수 있습니다.
- **버전별 정밀 탐색 및 보관 개수 제어**: 각 아티팩트의 스냅샷 타임스탬프 빌드 목록을 조회하여 최신 N개만 유지하고 나머지를 일괄 삭제할 수 있습니다.
- **안전한 실행 및 상세 로그 기록**: 삭제 시 생성되는 로그 파일은 `/tmp` 디렉토리에 고유 타임스탬프로 저장되며, 30일 경과 시 자동 청소됩니다.
- **인터럽트 안전 종료**: 실행 도중 언제든지 `Ctrl + C`를 누르면 즉시 작업을 안전하게 중단합니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 **Long Option** 전용으로 동작하며, Short Option은 지원하지 않습니다.

| 파라미터 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--group-id <id>` | 선택 | 조회/삭제 대상 Nexus Group ID (콤마로 다중 지정 가능) |
| `--artifact-id <id>` | 선택 | 조회/삭제 대상 Nexus Artifact ID (콤마로 다중 지정 가능, Group ID 필수) |
| `--help` | 선택 | 도움말 및 옵션 안내 출력 |

> [!IMPORTANT]
> 본 도구 실행 전 다음 환경 변수가 사전에 설정되어 있어야 합니다:
> - `NEXUS_URL`: 대상 Nexus 서버 베이스 URL (예: `http://nexus.internal:8081`)
> - `NEXUS_REPO`: 스냅샷 저장소 이름 (예: `maven-snapshots`)
> - `NEXUS_USER`: API 권한을 가진 계정명
> - `NEXUS_PASS`: 계정 비밀번호

---

## 🚀 사용 예시

### 1. 대화형 실행 (메뉴 선택)
```bash
nexus-snapshot-manager
```

### 2. 특정 그룹 ID 지정 실행
```bash
nexus-snapshot-manager --group-id "kr.co.ymtech,com.example"
```

### 3. 특정 아티팩트 ID까지 지정 실행
```bash
nexus-snapshot-manager --group-id "kr.co.ymtech" --artifact-id "core-module,web-module"
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./nexus-snapshot-manager --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./nexus-snapshot-manager --target global
```
