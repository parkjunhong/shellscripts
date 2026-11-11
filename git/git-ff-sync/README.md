# ⚡ git-ff-sync

원격 소스 브랜치(기본값: `origin/main`)의 변경사항을 대상 브랜치(기본값: `develop`)로 **최신화(`git fetch`) &rarr; 전환(`git switch`) &rarr; Fast-Forward 병합(`git merge --ff-only`) &rarr; 원격 반영(`git push`) &rarr; 원래 브랜치 복귀**까지 안전하고 선형적으로 일괄 수행하는 Git 동기화 CLI 도구입니다.

---

## ✨ 주요 특징

1. **안전한 4단계 선형 동기화 파이프라인 (Fast-Forward Only)**
   1. 원격 저장소 최신 참조 수신 (`git fetch <remote>`)
   2. 대상 브랜치로 전환 (`git switch <target>`)
   3. 원격 소스 브랜치 Fast-Forward 병합 (`git merge --ff-only <remote>/<source>`)
      * 대상 브랜치에 독자 커밋이 존재하여 분기(Diverge)된 경우, 커밋 히스토리를 보호하기 위해 아무것도 변경하지 않고 즉시 안전 중단
   4. 갱신된 대상 브랜치 원격 반영 (`git push <remote> <target>`)
2. **원래 작업 브랜치 자동 복귀 (Trap Handler)**
   * 스크립트 실행 시작 시점의 체크아웃 브랜치를 기억하여, 동기화 완료 후(또는 실패 시에도) 원래 머물던 브랜치로 자동 복귀합니다.
3. **사전 무결성 점검 (Pre-flight Validation)**
   * 작업 디렉토리에 커밋되지 않은 로컬 변경사항(Uncommitted changes)이 존재할 경우, 브랜치 이동 및 병합 중 데이터 유실을 방지하기 위해 작업을 사전에 차단합니다.
4. **시뮬레이션 모드 (`--dry-run`) 지원**
   * 실제 병합이나 원격 푸시를 실행하지 않고, 대상 브랜치가 소스 브랜치로 Fast-Forward 전진이 가능한 상태인지 사전 진단할 수 있습니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--remote <name>` | 선택 | `origin` | 원격 저장소 이름 |
| `--source <branch>` | 선택 | `main` | 병합할 원본 소스 브랜치 이름 |
| `--target <branch>` | 선택 | `develop` | 병합 대상 타겟 브랜치 이름 |
| `--dry-run` | 선택 | `false` | 실제 변경 없이 Fast-Forward 가능 여부만 시뮬레이션 진단 |
| `--help` | 선택 | - | 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1) 기본 설정으로 실행 ('origin/main' -> 'develop' 동기화 및 push 후 복귀)
./git-ff-sync

# 2) 시뮬레이션 모드로 Fast-Forward 가능 여부만 사전 점검
./git-ff-sync --dry-run

# 3) 커스텀 브랜치 간 Fast-Forward 동기화 ('origin/release' -> 'stage')
./git-ff-sync --source release --target stage

# 4) 커스텀 원격 저장소 지정 ('upstream/main' -> 'develop')
./git-ff-sync --remote upstream --source main --target develop
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./git-ff-sync --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./git-ff-sync --target global
```
