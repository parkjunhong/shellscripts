 # ⚡ env/commands (사후 구성 명령어)

`env/commands/` 디렉토리는 OS 패키지, 소프트웨어 인스톨러, CLI 도구 설치가 완료된 후 시스템 정책, 네트워크/방화벽 규칙 초기화, 데몬 설정 등 **시스템 환경 구성을 마무리(Finalize)**하기 위해 실행되는 사후 구성 명령어 스크립트들을 제공합니다.

모든 명령어는 Canonical 디렉토리 구조(`<name>/<name>`)를 준수하며 단독 실행이 가능합니다.

---

## 📋 제공되는 명령어 목록

| 명령어 식별자 | Canonical 디렉토리 | 설명 | 지원 OS |
| :--- | :--- | :--- | :--- |
| `firewall-cmd-set-priority` | [`firewall-cmd-set-priority`](./firewall-cmd-set-priority/) | firewalld 방화벽 정책의 존(Zone) 및 체인 우선순위를 초기화 및 동기화 | Linux 전용 (firewalld) |

---

## ⚙️ 실행 및 연동 가이드

### 1. `sciectl` 통합 실행 (권장)
`sciectl` 트랜잭션 파이프라인의 **Step 7 (사후 구성 명령어)** 단계에서 실행됩니다.

```bash
# 카탈로그를 통한 일괄 실행
sciectl install --catalog network

# 특정 사후 구성 명령어만 단독 실행
sciectl install --command firewall-cmd-set-priority
```

### 2. 단독 직접 실행
```bash
./firewall-cmd-set-priority/firewall-cmd-set-priority
```
