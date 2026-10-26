# 🔀 git-merge

소스(Source) 브랜치의 변경 사항을 타겟(Target) 브랜치로 **최신화(`git pull`) &rarr; 병합(`git merge`) &rarr; 원격 반영(`git push`) &rarr; 원래 작업 브랜치 복귀(`git checkout`)**까지 안전하게 일괄 수행하는 CLI 도구입니다.

---

## ✨ 주요 특징

1. **안전한 5단계 브랜치 병합 파이프라인 자동화**
   1. 소스 브랜치 체크아웃 및 `git pull` (단, `-l/--local-source` 지정 시 생략)
   2. 타겟 브랜치 체크아웃 및 `git pull`
   3. 타겟 브랜치에서 소스 브랜치 병합(`git merge`)
   4. 병합된 타겟 브랜치 원격 푸시(`git push`)
   5. 실행 전 머물고 있던 원래 브랜치로 자동 복귀
2. **대화형 브랜치 선택 및 스마트 기본값 할당**
   * `-s/--source`와 `-t/--target`을 모두 생략하면 로컬 브랜치 목록을 번호와 함께 출력하여 대화형으로 선택할 수 있습니다.
   * 둘 중 하나만 지정한 경우, 생략된 쪽은 현재 체크아웃된 브랜치로 자동 설정됩니다.
3. **사전 무결성 점검 (Uncommitted 변경사항 보호)**
   * 병합 시작 전 커밋되지 않은 변경 사항(`git diff-index --quiet HEAD --`)이 존재하면 작업 손실을 막기 위해 즉시 중단하고 커밋 또는 스태시(stash)를 안내합니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 단축 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :---: | :--- |
| `--source <branch>` | `-s` | 선택 | 병합할 원본(Source) 브랜치 이름 |
| `--target <branch>` | `-t` | 선택 | 병합 대상(Target) 브랜치 이름 |
| `--local-source` | `-l` | 선택 | 소스 브랜치가 원격 없이 로컬에만 존재하는 경우 사용 (`source` 브랜치의 `git pull` 생략) |
| `--help` | `-h` | 선택 | 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1) 'feature/login' 브랜치를 'develop' 브랜치로 병합 및 푸시 후 원래 브랜치로 복귀
./git-merge --source feature/login --target develop

# 2) 로컬 전용 브랜치를 'develop'에 병합 (소스 브랜치 git pull 생략)
./git-merge -s feature/local-test -t develop --local-source

# 3) 옵션 없이 실행하여 번호 선택 방식으로 소스/타겟 브랜치 지정
./git-merge
```
