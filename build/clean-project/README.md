# clean-project

지정된 디렉토리 하위에서 Git 저장소(`.git`) 또는 프로젝트 루트(`.project`)를 갖는 모든 프로젝트 디렉토리를 재귀적으로 탐색하여 빌드 산출물 디렉토리인 `deploy/` 및 `target/`을 일괄 정리하고 디스크 공간을 확보하는 최신 빌드 부산물 청소 도구입니다.

---

## ✨ 주요 특징

- **스마트 프로젝트 감지**: `.git` 디렉토리 또는 `.project` 파일이 존재하는 유효 프로젝트 디렉토리만 선별하여 안전하게 탐색합니다.
- **빌드 부산물 일괄 정리**: 각 프로젝트 내의 `deploy/` 및 `target/` 디렉토리를 동시에 감지하여 불필요한 빌드 아티팩트를 깨끗하게 삭제합니다.
- **실시간 진행률 표시줄**: `⏳ [진행률: 00.00%] | 전체 / 처리 / 정리완료` 형식의 동적 단일 라인 진행률 표시줄을 렌더링합니다.
- **상세 결과 리포팅**: 탐색된 프로젝트 총합, `deploy` 삭제 개수, `target` 삭제 개수 및 실제 삭제된 프로젝트 목록을 일목요연하게 요약 출력합니다.
- **Bash 자동완성 지원**: `-d`, `--directory` 옵션 뒤에서 디렉토리 경로 자동완성을 매끄럽게 지원합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 단축 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :---: | :--- |
| `--directory <경로>` | `-d` | **필수** | 탐색 및 정리를 시작할 기준 루트 디렉토리 경로 |
| `--help` | `-h` | 선택 | 도구 사용법 및 도움말을 출력합니다. |

---

## 🚀 사용 예시

### 1. 특정 작업 디렉토리 하위 프로젝트 일괄 정리
```bash
clean-project -d /home/user/workspace
# 또는
clean-project --directory /home/user/workspace
```

### 2. 현재 디렉토리 기준 정리
```bash
clean-project -d .
```

**실행 결과 예시:**
```text
🔍 [1/2] 작업대상 디렉토리 정보를 수집 중입니다... (기준: /home/user/workspace)
🚀 [2/2] 총 5개의 프로젝트 디렉토리를 발견했습니다. 처리를 시작합니다.

🗑️  [삭제완료] /home/user/workspace/project-a ('deploy' 'target' 삭제됨)
✅ [유지됨] /home/user/workspace/project-b (삭제 대상 없음)
🗑️  [삭제완료] /home/user/workspace/project-c ('target' 삭제됨)

================================================================================
📊 [작업 결과 요약]
================================================================================
 🔹 탐색된 전체 프로젝트 디렉토리 개수 : 5 개
 🔹 'deploy' 디렉토리 삭제 개수        : 1 개
 🔹 'target' 디렉토리 삭제 개수        : 2 개
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./clean-project --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./clean-project --target global
```
