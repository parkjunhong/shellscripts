# 📊 mtr-netstat-conns

시스템의 네트워크 소켓 연결 상태(`netstat`)를 실시간으로 모니터링하고, 복잡한 네트워크 트래픽 환경에서 **다중 파이프라인 필터링(`--filter`)** 및 **정렬(`--sort`)** 옵션을 통해 원하는 포트, IP, 프로세스, 연결 상태를 정밀하게 추출·분석하는 네트워크 연결 상태 모니터링 CLI 도구입니다.

---

## ✨ 주요 특징

1. **다중 조건 파이프라인 필터링 (`--filter`)**
   * 파이프(`|`) 구분자를 활용하여 여러 필터링 조건을 연속 체인 방식으로 적용할 수 있습니다.
   * `grep`의 정규식(`-E`), 제외(`-v`) 옵션 구문을 그대로 수용하여 특정 IP/포트 제외, 복합 정규식 매칭이 가능합니다.
2. **유연한 정렬 옵션 (`--sort`)**
   * 로컬 주소(`local`), 원격 주소(`remote`), 프로세스 식별자(`pid`) 기준으로 오름차순(`/a`) 또는 내림차순(`/d`) 정렬을 지원합니다.
3. **netstat 옵션 직접 전달**
   * `-napt` 기본값 외에도 사용자가 지정한 임의의 netstat 플래그(예: `-anp`, `-ulnt`)를 직접 전달할 수 있습니다.
4. **가독성 높은 서식 출력**
   * 검색 결과와 함께 컬럼 헤더를 유지하여 수많은 연결 로그 중에서도 원하는 정보를 한눈에 파악할 수 있도록 서식을 구성합니다.
5. **지능형 Bash 자동 완성 (`mtr-netstat-conns.completion`)**
   * `--filter`, `--sort`, `-h` 등 CLI 옵션 자동 완성을 지원합니다.

---

## ⚙️ 파라미터 명세

```bash
mtr-netstat-conns [netstat-옵션] [--filter "<필터조건1> | <필터조건2>..."] [--sort <정렬기준>]
```

| 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `-[문자열]` | 선택 | `-napt` | `netstat` 명령어에 직접 전달할 플래그 (예: `-anpt`, `-uln`) |
| `--filter "<조건>"` | 선택 | - | 조회 결과를 파이프(`\|`)로 연속 필터링할 조건 문자열 |
| `--sort <기준>` | 선택 | - | 정렬 기준 및 방향 (`local`, `remote`, `pid` / 접미사: `/a` 오름차순, `/d` 내림차순) |
| `-h`, `--help` | 선택 | - | 도움말 메시지 출력 및 종료 |

### 필터 조건 작성 가이드
* **단순 문자열 매칭**: 특정 포트, IP, 상태, 프로세스명 (예: `8080`, `ESTABLISHED`, `java`)
* **정규식 다중 조건**: `-E ':80|:443'` (80 또는 443 포트)
* **제외 조건**: `-v TIME_WAIT`, `-v 127.0.0.1`

---

## 🚀 사용 예시

```bash
# 1) 기본 연결 상태 조회 (기본값: netstat -napt)
./mtr-netstat-conns

# 2) 특정 포트(8080) 및 ESTABLISHED 상태만 필터링
./mtr-netstat-conns --filter "8080 | ESTABLISHED"

# 3) 정규식을 이용한 웹 포트(80, 443)의 ESTABLISHED 연결 조회
./mtr-netstat-conns --filter "-E ':80|:443' | ESTABLISHED"

# 4) 불필요한 TIME_WAIT 및 루프백(127.0.0.1) 트래픽 제외
./mtr-netstat-conns --filter "-v TIME_WAIT | -v 127.0.0.1"

# 5) 자바(java) 프로세스가 LISTEN 중인 포트 조회 및 로컬 주소 오름차순 정렬
./mtr-netstat-conns --filter "LISTEN | java" --sort local/a

# 6) 특정 원격 IP(192.168.1.50)와 연결된 nginx 세션을 PID 내림차순 정렬
./mtr-netstat-conns --filter "192.168.1.50 | nginx | ESTABLISHED" --sort pid/d
```
