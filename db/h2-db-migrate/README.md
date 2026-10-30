# h2-db-migrate

`h2-db-migrate`는 H2 데이터베이스 버전 변경(예: 1.4.x &rarr; 2.x)에 따른 데이터 이관(Migration), 데이터 추출(Backup), 신규 DB 복원(Restore)을 안전하게 처리할 수 있는 대화형 CLI 도구입니다.

---

## ✨ 주요 특징

- **3가지 모드 지원**:
  - `m` (이관 모드): 데이터 추출 후 신규 버전 DB 복원 및 임시 생성물 자동 정리
  - `b` (추출 모드): 기존 H2 버전에서 SQL 스크립트 추출 및 원본 백업
  - `r` (복원 모드): 추출된 SQL 스크립트로부터 신규 H2 버전 DB 복원
- **대화형 안내 인터페이스**: 파라미터 없이 실행 시 데이터 파일 경로, H2 버전, 라이브러리 경로, 사용자 계정을 단계별로 안내받아 안전하게 입력할 수 있습니다.
- **메타데이터 자동 보존**: 백업 SQL 파일에 계정 정보 및 버전 정보를 메타데이터 주석으로 자동 기록하여 복원 시 간편하게 재사용할 수 있습니다.
- **안전한 자동 롤백**: 복원 실패 시 기존 원본 백업 파일을 즉시 복구합니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 대화형(Interactive) 실행을 기본으로 하며, 파라미터는 **Long Option** 전용으로 동작합니다.

| 파라미터 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--help` | 선택 | 도움말 및 사용법 안내 출력 |

---

## 🚀 사용 예시

### 대화형 실행
```bash
h2-db-migrate
```
실행 후 터미널에 표시되는 프롬프트에 따라 작업 모드, DB 파일 경로, H2 버전 등을 입력합니다.

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./h2-db-migrate --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./h2-db-migrate --target global
```
