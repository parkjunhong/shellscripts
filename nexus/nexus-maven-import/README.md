# nexus-maven-import

`nexus-maven-import`는 로컬 디렉토리에 백업되거나 내보내진 Maven 아티팩트(`jar`, `pom`, `war` 등)들을 Sonatype Nexus Repository의 지정된 저장소로 일괄 업로드하고 마이그레이션하는 고도화된 운영 관리 CLI 도구입니다.

---

## ✨ 주요 특징

- **저장소 1:1 매핑 업로드**: `--repository-map <src_repo>=<target_repo>` 옵션을 통해 원본 저장소 구조를 새로운 대상 저장소로 유연하게 변환하여 업로드합니다.
- **원격 존재 여부 사전 검증**: 기본적으로 Nexus REST API를 조회하여 원격에 이미 동일 아티팩트가 존재하는지 검증하고 건너뜁니다. (강제 덮어쓰기는 `--force`, 원격 검증 생략은 `--no-verify`)
- **실패 자동 재시도 및 백오프**: 네트워크 불안정에 대비하여 지수 백오프 기반의 자동 재시도 로직을 탑재하고 있습니다.
- **체크섬 및 메타데이터 스마트 처리**: Nexus가 자체 계산하는 체크섬 파일(`.sha1`, `.md5` 등)을 스마트하게 필터링하며 필요 시 `--include-checksum-assets`로 포함할 수 있습니다.
- **작업 제한 및 부분 마이그레이션**: `--path-prefix`를 통한 특정 경로 필터링 및 `--limit`을 통한 테스트 업로드 건수 제한을 지원합니다.
- **Dry-run 시뮬레이션 지원**: `--dry-run` 옵션으로 실제 파일 업로드 없이 업로드 대상 목록 및 계획을 안전하게 확인합니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 **Long Option** 전용으로 동작하며, Short Option은 지원하지 않습니다.

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :--- | :--- |
| `--url <URL>` | 선택 | `http://localhost:8081` | 대상 Nexus 서버 베이스 URL |
| `--user <사용자명>` | 선택 | `migration-test` | Nexus 접속 사용자 계정 |
| `--input <디렉토리>` | 선택 | `./nexus-export` | 업로드할 아티팩트가 위치한 최상위 디렉토리 |
| `--repository-map <원문=대상>` | 선택 | 기본 릴리스/스냅샷 매핑 | 저장소 매핑 규칙 (예: `maven-releases=target-releases`) |
| `--path-prefix <접두어>` | 선택 | 없음 | 특정 하위 경로(그룹 ID 등)만 필터링하여 업로드 |
| `--limit <개수>` | 선택 | `0` (전체) | 업로드할 최대 아티팩트 개수 제한 |
| `--dry-run` | 선택 | `false` | 실제 업로드를 수행하지 않고 계획만 시뮬레이션 출력 |
| `--force` | 선택 | `false` | 원격에 동일 파일이 존재해도 강제 덮어쓰기 업로드 |
| `--no-verify` | 선택 | `false` | 업로드 전 원격 존재 여부 사전 검증 생략 |
| `--include-checksum-assets` | 선택 | `false` | `.sha1`, `.md5` 등의 체크섬 파일도 함께 업로드 |
| `--insecure` | 선택 | `false` | HTTPS 인증서 검증 비활성화 (`curl -k`) |
| `--verbose` | 선택 | `false` | 상세 디버그 로그 출력 |
| `--help` | 선택 | - | 도움말 및 옵션 안내 출력 |

> [!TIP]
> Nexus 사용자 비밀번호는 보안을 위해 명령행 인자가 아닌 `NEXUS_PASSWORD` 환경 변수를 사용하거나 실행 시 대화형 프롬프트로 입력하는 것을 권장합니다.

---

## 🚀 사용 예시

### 1. 기본 일괄 임포트 실행
```bash
nexus-maven-import --url "http://nexus.internal:8081" --user admin --input ./nexus-export
```

### 2. 저장소 매핑 및 경로 필터링 적용
```bash
nexus-maven-import --url "http://nexus.internal:8081" \
  --input ./backup \
  --repository-map "old-releases=new-releases" \
  --path-prefix "kr/co/ymtech"
```

### 3. Dry-run 사전 검증 (10건 제한)
```bash
nexus-maven-import --input ./nexus-export --limit 10 --dry-run
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./nexus-maven-import --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./nexus-maven-import --target global
```
