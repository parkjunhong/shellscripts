# es-index-usage

`es-index-usage`는 Elasticsearch 클러스터의 인덱스 정보를 조회하여 각 인덱스별 및 전체 인덱스의 샤드(Primary/Replica) 개수, 문서 수, 샤드당 평균 문서 수, 총 저장소 사용량(GB/TB)을 정밀 집계하여 출력하는 모니터링 CLI 도구입니다.

---

## ✨ 주요 특징

- **샤드 및 문서 수 종합 분석**: Primary 및 Replica 샤드 수를 개별 집계하고, 샤드당 평균 문서 수를 자동 계산합니다.
- **단위 자동 환산 및 정밀 계산**: `b`, `kb`, `mb`, `gb` 등 다양한 단위로 반환되는 ES 메트릭을 `bc`를 통해 정밀하게 합산하여 GB 및 TB 단위로 일목요연하게 표시합니다.
- **접두어 일괄 적용**: `--index-prefix` 옵션을 통해 인덱스명 공통 접두어를 손쉽게 일괄 적용할 수 있습니다.
- **다중 인덱스 쉼표 구분 조회**: 여러 개의 인덱스를 쉼표(`,`)로 구분하여 한 번에 지정할 수 있습니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 **Long Option** 전용으로 동작하며, Short Option은 지원하지 않습니다.

| 파라미터 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--ip <IP주소>` | **필수** | Elasticsearch 서버 IP 주소 |
| `--port <포트>` | **필수** | Elasticsearch HTTP 포트 (예: `9200`) |
| `--indices <인덱스목록>` | **필수** | 조회할 인덱스 목록 (쉼표 구분) |
| `--index-prefix <접두어>` | 선택 | 인덱스 이름 앞에 붙일 공통 접두어 |
| `--help` | 선택 | 도움말 및 사용법 안내 출력 |

---

## 🚀 사용 예시

### 1. 단일 또는 다중 인덱스 용량 조회
```bash
es-index-usage --ip 192.168.1.100 --port 9200 --indices "logs-2026.10,logs-2026.09"
```

### 2. 공통 인덱스 접두어 적용
```bash
es-index-usage --ip 192.168.1.100 --port 9200 --index-prefix "service-" --indices "auth,order,payment"
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./es-index-usage --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./es-index-usage --target global
```
