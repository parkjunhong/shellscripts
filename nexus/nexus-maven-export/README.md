# nexus-maven-export

`nexus-maven-export`는 Sonatype Nexus Repository의 지정된 저장소들로부터 전체 Maven 아티팩트(`jar`, `pom`, `war` 등)를 페이지네이션(`continuationToken`) 방식으로 전수 조회하여 로컬 디렉터리로 계층적 디렉터리 구조를 유지하며 일괄 다운로드(내보내기)하는 CLI 도구입니다.

---

## ✨ 주요 특징

- **대용량 저장소 안전 순회**: Nexus REST API의 `continuationToken`을 활용하여 수만 개 이상의 아티팩트가 존재하는 대규모 저장소도 메모리 누수 없이 안정적으로 순회합니다.
- **다중 저장소 동시 지정**: `--repository` 옵션을 여러 번 사용하여 여러 저장소(`maven-releases`, `maven-snapshots` 등)를 순차적으로 일괄 내보낼 수 있습니다.
- **원래의 Maven 그룹/아티팩트 구조 보존**: Nexus 내부 경로(`downloadUrl`의 상대 경로)를 해석하여 원본과 동일한 디렉터리 트리(`kr/co/ymtech/...`)로 자동 저장합니다.
- **실패 자동 재시도 및 로깅**: 다운로드 실패 시 자동 재시도하며, 작업별 고유 실행 ID(`RUN_ID`)와 상세 로그를 생성합니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 **Long Option** 전용으로 동작하며, Short Option은 지원하지 않습니다.

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :--- | :--- |
| `--url <URL>` | 선택 | `http://localhost:8081` | 원본 Nexus 서버 베이스 URL |
| `--user <사용자명>` | 선택 | `admin` | Nexus 접속 사용자 계정 |
| `--output <디렉토리>` | 선택 | `./nexus-export` | 아티팩트가 다운로드될 최상위 디렉토리 |
| `--repository <저장소명>` | 선택 | 기본 저장소 세트 | 내보낼 Nexus 저장소명 (다중 지정 가능) |
| `--insecure` | 선택 | `false` | HTTPS 인증서 검증 비활성화 (`curl -k`) |
| `--verbose` | 선택 | `false` | 상세 디버그 로그 출력 |
| `--help` | 선택 | - | 도움말 및 옵션 안내 출력 |

> [!TIP]
> 비밀번호는 명령행 옵션 대신 `NEXUS_PASSWORD` 환경 변수를 사용하거나 실행 시 대화형 프롬프트로 안전하게 입력할 수 있습니다.

---

## 🚀 사용 예시

### 1. 기본 저장소 전체 내보내기
```bash
nexus-maven-export --url "http://nexus.internal:8081" --user admin --output ./backup
```

### 2. 특정 저장소만 지정하여 내보내기
```bash
nexus-maven-export --url "http://nexus.internal:8081" \
  --output ./export-releases \
  --repository "maven-releases" \
  --repository "custom-releases"
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./nexus-maven-export --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./nexus-maven-export --target global
```
