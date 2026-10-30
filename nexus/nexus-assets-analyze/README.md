# nexus-assets-analyze

`nexus-assets-analyze`는 Sonatype Nexus Repository의 지정된 저장소에 저장된 모든 Asset들을 REST API로 전수 조회하여, 자산 목록 파일 생성, 총 용량 및 자산 개수 집계, 파일 확장자별 분포 분석 리포트를 생성하는 분석 CLI 도구입니다.

---

## ✨ 주요 특징

- **대용량 저장소 안전 순회**: `continuationToken` 기반 페이징을 통해 수십만 개 단위의 자산 정보도 빠르고 안정적으로 수집합니다.
- **다중 저장소 동시 분석**: 기본 저장소(`maven-releases`, `maven-snapshots`) 외에 `--repo` 옵션을 여러 번 사용하여 분석할 저장소를 유연하게 지정할 수 있습니다.
- **상세 통계 리포트 생성**:
  - `assets.tsv`: 각 자산의 경로, 크기(bytes), 최종 수정일, 다운로드 URL 원본 목록
  - `summary.txt`: 저장소별 총 자산 수, 합산 용량(bytes 및 인간 친화적 단위) 요약
  - `extensions.txt`: `.jar`, `.pom`, `.xml` 등 확장자별 개수 분포 집계
- **표준 Long Option 체계**: 직관적인 롱 옵션과 상황별 스마트 Bash 자동완성을 지원합니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 **Long Option** 전용으로 동작하며, Short Option은 지원하지 않습니다.

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :--- | :--- |
| `--url <URL>` | 선택 | `http://localhost:8081` | 대상 Nexus 서버 베이스 URL |
| `--user <사용자명>` | 선택 | `admin` | Nexus 접속 사용자 계정 |
| `--pass <비밀번호>` | **필수** | 없음 | Nexus 접속 비밀번호 (환경 변수 `NEXUS_PASSWORD`로 대체 가능) |
| `--repo <저장소명>` | 선택 | `maven-releases`, `maven-snapshots` | 분석할 Nexus 저장소명 (다중 지정 가능) |
| `--output <디렉토리>` | 선택 | `./nexus-analysis` | 분석 결과 파일들이 저장될 출력 디렉토리 |
| `--help` | 선택 | - | 도움말 및 옵션 안내 출력 |

---

## 🚀 사용 예시

### 1. 기본 분석 실행 (환경 변수 비밀번호 사용)
```bash
export NEXUS_PASSWORD="mypassword"
nexus-assets-analyze --url "http://nexus.internal:8081" --user admin
```

### 2. 특정 저장소 및 출력 디렉토리 지정
```bash
nexus-assets-analyze --url "http://nexus.internal:8081" \
  --user admin --pass "mypassword" \
  --repo "custom-releases" \
  --repo "third-party" \
  --output ./analysis_report
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./nexus-assets-analyze --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./nexus-assets-analyze --target global
```
