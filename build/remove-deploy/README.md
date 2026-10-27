# remove-deploy

지정된 디렉토리 하위의 프로젝트들을 탐색하여 컴파일 산출물(`target/`)은 유지하면서 배포 디렉토리인 `deploy/`만 선별적으로 안전하게 삭제하는 전문 배포 디렉토리 정리 도구입니다.

---

## ✨ 주요 특징

- **배포 산출물 선별 정리**: 재컴파일 부담이 있는 `target/` 디렉토리는 보존하면서 이전 배포 결과물(`deploy/`)만 깔끔하게 제거합니다.
- **프로젝트 루트 자동 감지**: `.git` 디렉토리 또는 `.project` 파일이 위치한 프로젝트 단위 디렉토리만 정확하게 식별합니다.
- **실시간 터미널 진행률 표시**: 대량의 마이크로서비스 또는 다중 프로젝트 디렉토리 처리 시 실시간 작업 진행률(`draw_progress`)을 제공합니다.
- **결과 통계 리포팅**: 탐색된 프로젝트 총 개수와 삭제된 `deploy` 디렉토리 수를 명확하게 요약하여 출력합니다.
- **Bash 자동완성 지원**: 디렉토리 경로 완성 및 옵션 추천을 원활하게 제공합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 단축 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :---: | :--- |
| `--directory <경로>` | `-d` | **필수** | 탐색 및 정리를 시작할 기준 루트 디렉토리 경로 |
| `--help` | `-h` | 선택 | 도구 사용법 및 도움말을 출력합니다. |

---

## 🚀 사용 예시

### 1. 대상 디렉토리 하위 배포 폴더 일괄 정리
```bash
remove-deploy -d /home/user/workspace/microservices
# 또는
remove-deploy --directory /home/user/workspace/microservices
```

### 2. 현재 작업 경로 기준 실행
```bash
remove-deploy -d .
```

---

## 💻 Bash 자동완성 설정

```bash
# 개인 계정 적용 (~/.bashrc)
source /path/to/shellscripts/build/remove-deploy/remove-deploy.completion

# 시스템 전역 적용
sudo cp /path/to/shellscripts/build/remove-deploy/remove-deploy.completion /etc/bash_completion.d/
```
