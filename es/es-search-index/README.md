# es-search-index

`es-search-index`는 Elasticsearch 인덱스에서 타임스탬프 범위를 기반으로 문서를 검색하고, 지정된 필드 속성들을 추출하여 출력하는 CLI 도구입니다.

---

## ✨ 주요 특징

- **타임스탬프 범위 기반 검색**: `--gte` 및 `--lt` 파라미터를 통해 밀리초 단위의 타임스탬프 범위로 정밀하게 필터링합니다.
- **원하는 필드 데이터만 동적 추출**: `--props` 옵션에 필드 목록을 지정하여 `_source` 내부의 원하는 속성들만 쉼표로 연결하여 추출합니다.
- **조회 건수 제한**: `--size` 옵션을 통해 조회할 최대 문서 수를 제어할 수 있습니다.
- **jq 기반의 빠른 파싱**: JSON 응답 데이터를 `jq`를 통해 고속으로 추출합니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 **Long Option** 전용으로 동작하며, Short Option은 지원하지 않습니다.

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :--- | :--- |
| `--host <호스트>` | **필수** | - | Elasticsearch 서버 호스트 주소 또는 IP |
| `--index <인덱스명>` | **필수** | - | 검색할 Elasticsearch 인덱스 이름 |
| `--gte <타임스탬프>` | **필수** | - | 검색 시작 타임스탬프 (밀리초) |
| `--lt <타임스탬프>` | **필수** | - | 검색 종료 타임스탬프 (밀리초) |
| `--port <포트>` | 선택 | `9200` | Elasticsearch HTTP 포트 |
| `--props <필드목록>` | 선택 | `timestamp vip rootServer ...` | 추출할 필드 목록 (공백 구분) |
| `--size <문서수>` | 선택 | `10` | 조회할 최대 문서 개수 |
| `--help` | 선택 | - | 도움말 및 옵션 안내 출력 |

---

## 🚀 사용 예시

### 1. 기본 범위 검색
```bash
es-search-index --host 192.168.1.100 --port 9200 --index "traffic-logs" --gte 1718636400000 --lt 1718724600000
```

### 2. 특정 필드 지정 및 크기 제한
```bash
es-search-index --host es-server --index "access-log" --gte 1718636400000 --lt 1718724600000 --props "timestamp client_ip status" --size 50
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./es-search-index --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./es-search-index --target global
```
