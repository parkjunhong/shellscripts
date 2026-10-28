# uuid-list

시스템의 `uuidgen` 유틸리티를 기반으로 지정한 개수만큼 고유 UUID(Universally Unique Identifier)를 연속 생성하여 표준 출력으로 반환하는 경량 생성 도구입니다.

---

## ✨ 주요 특징

- **대량 고유 UUID 일괄 생성**: 테스트 데이터 생성, 분산 시스템 키 생성 등에 필요한 고유 식별자(UUID)를 원하는 수량만큼 빠르게 생성합니다.
- **기본값 지원**: 개수 인자를 생략할 경우 기본 1개의 UUID를 생성합니다.
- **입력 유효성 검증**: 숫자가 아닌 잘못된 인자가 전달될 경우 즉시 오류를 감지하고 도움말을 표시합니다.
- **지능형 Bash 자동완성**: 자주 사용하는 생성 단위(1, 5, 10, 20, 50, 100 등)를 추천합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `<count>` | 선택 | `1` | 생성할 UUID의 개수 (양의 정수) |
| `--help` | 선택 | - | 도움말 메시지를 표시합니다. |

---

## 🚀 사용 예시

### 1. 단일 UUID 생성 (기본값)
```bash
uuid-list
```

### 2. 5개의 UUID 연속 생성
```bash
uuid-list 5
```

### 3. 생성된 UUID 목록을 파일로 저장
```bash
uuid-list 100 > ./uuids.txt
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../scriptctl/scriptctl install --script ./uuid-list --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../scriptctl/scriptctl install --script ./uuid-list --target global
```
