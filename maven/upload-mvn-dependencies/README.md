# upload-mvn-dependencies

로컬 Maven 캐시(`~/.m2/repository`) 또는 특정 디렉토리에 저장된 아티팩트(`jar`, `war`, `pom` 등)를 탐색하여 사설 원격 Maven 저장소(Nexus, Artifactory 등)의 Releases 및 Snapshots 저장소에 일괄 업로드(`mvn deploy:deploy-file`)하는 마이그레이션 및 동기화 도구입니다.

---

## ✨ 주요 특징

- **로컬 아티팩트 일괄 업로드**: 망분리 환경 구축이나 원격 저장소 마이그레이션 시 로컬 의존성을 일괄 배포할 수 있습니다.
- **릴리즈/스냅샷 자동 분기**: 아티팩트의 버전에 `SNAPSHOT` 표기가 포함되어 있는지 여부를 감지하여 지정된 릴리즈 또는 스냅샷 저장소 엔드포인트로 자동 분류하여 전송합니다.
- **메타데이터 자동 추출**: 디렉토리 구조 및 `pom.xml` 정보를 기반으로 `groupId`, `artifactId`, `version`, `packaging` 정보를 자동 추출하여 배포합니다.
- **안전한 실행 분리 (`--run`)**: 기본 실행 시에는 파라미터 및 대상 경로를 검증하여 설정 정보를 브리핑하고, 명시적으로 `--run` 옵션을 지정했을 때만 실제 업로드를 수행하여 오배포를 방지합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 단축 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :---: | :--- |
| `--url <url>` | `-u` | **필수** | - | Maven 저장소 루트 URL (예: `http://nexus.local:8081`) |
| `--releases <path>` | `-r` | **필수** | - | 릴리즈 아티팩트 저장소 경로 (예: `repository/maven-releases`) |
| `--snapshots <path>` | `-s` | **필수** | - | 스냅샷 아티팩트 저장소 경로 (예: `repository/maven-snapshots`) |
| `--m2_dir <path>` | `-m` | **필수** | - | 업로드 대상 의존성 파일들이 위치한 로컬 디렉토리 경로 |
| `--run` | - | 선택 | 비활성 | 실제 아티팩트 업로드를 수행합니다. (미지정 시 파라미터 검증만 수행) |
| `--help` | `-h` | 선택 | - | 사용법 및 옵션 도움말을 출력합니다. |

---

## 🚀 사용 예시

### 1. 설정값 검증 (Dry-run 성격의 브리핑)
```bash
upload-mvn-dependencies \
  -u http://192.168.0.10:8081 \
  -r repository/maven-releases \
  -s repository/maven-snapshots \
  -m ~/.m2/repository
```

### 2. 실제 의존성 일괄 업로드 실행
```bash
upload-mvn-dependencies \
  -u http://192.168.0.10:8081 \
  -r repository/maven-releases \
  -s repository/maven-snapshots \
  -m ~/.m2/repository \
  --run
```
