# mvn-deploy

표준 `mvn -e clean deploy` 골(goal)을 기반으로 원격 Maven 저장소(Nexus, Artifactory 등)에 아티팩트를 배포할 때, 스냅샷 갱신, 테스트 생략, 사용자 정의 `settings.xml` 및 프로파일 적용을 간결하고 안전하게 처리해 주는 배포 헬퍼 도구입니다.

---

## ✨ 주요 특징

- **표준 배포 프로세스 자동화**: `mvn -e clean deploy`를 기본으로 실행하여 안정적인 패키징 및 원격 배포를 보장합니다.
- **간결한 플래그 지원**: 긴 Maven 시스템 속성 대신 `-U` (스냅샷 업데이트), `-s` (`-DskipTests`) 등 직관적인 단축 플래그를 제공합니다.
- **유연한 설정 및 프로파일 연동**: 커스텀 `--settings <path>` 지정과 다중 `--profile <name>` 적용을 완벽히 지원하며, `~` 홈 디렉토리 경로를 자동으로 확장합니다.
- **사전 검증용 Dry-run 모드**: `--dry-run` 플래그를 통해 실제로 배포를 수행하기 전 조립된 전체 `mvn` 명령어를 미리 확인할 수 있습니다.
- **추가 Maven 인자 분리 전달**: `--` 구분자를 지원하여 표준 플래그 외의 임의 Maven 인자(예: `--batch-mode`, `-Drevision=...`)를 그대로 전달할 수 있습니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--update-snapshots` | 선택 | 비활성 | 원격 저장소의 스냅샷 의존성을 강제로 업데이트합니다 (`mvn -U`). |
| `--skip-tests` | 선택 | 비활성 | 배포 전 단위 테스트를 건너뜁니다 (`-DskipTests`). |
| `--maven <path>` | 선택 | `mvn` | 사용할 Maven 실행 파일의 경로 또는 커맨드를 지정합니다. |
| `--settings <path>` | 선택 | - | 사용할 `settings.xml` 파일 경로를 지정합니다 (`mvn -s <path>`). |
| `--profile <name>` | 선택 | - | 활성화할 Maven 프로파일을 지정합니다 (`mvn -P <name>`, 다중 지정 가능). |
| `--dry-run` | 선택 | 비활성 | 명령을 실제 실행하지 않고 조립된 Maven 커맨드만 출력합니다. |
| `--help` | 선택 | - | 사용법 및 옵션 도움말을 출력합니다. |
| `-- <extra args...>` | 선택 | - | Maven 실행 시 그대로 전달할 추가 파라미터 목록입니다. |

---

## 🚀 사용 예시

### 1. 기본 클린 배포
```bash
mvn-deploy
```

### 2. 스냅샷 강제 갱신 및 테스트 생략 배포
```bash
mvn-deploy --update-snapshots --skip-tests
```

### 3. 사용자 정의 settings.xml 및 특정 프로파일 배포
```bash
mvn-deploy --settings ~/.m2/settings-corporate.xml --profile release
```

### 4. 실제 배포 전 명령어 검증 (Dry-run)
```bash
mvn-deploy -U -s --profile prod --dry-run
```

### 5. 추가 Maven 인자 전달
```bash
mvn-deploy -U -- --batch-mode -Drevision=2.1.0
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./mvn-deploy --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./mvn-deploy --target global
```
