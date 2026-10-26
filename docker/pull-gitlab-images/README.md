# 🦊 pull-gitlab-images

지정된 하나 이상의 GitLab 버전(직접 입력 또는 파일 입력)에 대해 **GitLab 공식 Docker 이미지(`gitlab/gitlab-ee` 또는 `gitlab/gitlab-ce`)를 다운로드(`docker pull`)**하고, 선택적으로 오프라인 배포용 **`.tar` 아카이브 파일로 저장(`docker save`)**하는 스크립트입니다.

---

## ✨ 주요 특징

1. **다양한 버전 입력 방식 지원 (`--version`, `--file`)**
   * `--version` 옵션을 통해 콤마(`,`)로 구분된 복수의 GitLab 버전을 한 번에 지정할 수 있습니다.
   * `--file` 옵션을 통해 줄바꿈으로 작성된 버전 목록 텍스트 파일(빈 줄 및 `#` 주석 자동 무시, CRLF 자동 정제)을 읽어들일 수 있습니다.
2. **스마트 버전 태그 보정 및 에디션(EE/CE) 대화형 선택**
   * `17.5.1-ee.0`, `17.5.1-ce.0` 형태뿐만 아니라 빌드 번호가 생략된 `17.5.1-ee`(`-> 17.5.1-ee.0` 자동 교정)나 순수 버전 번호 `17.5.1`(대화형 프롬프트로 `EE`/`CE` 선택 후 자동 조합) 입력을 모두 지원합니다.
3. **중복 작업 방지 및 오프라인 아카이브(`.tar`) 생성**
   * 로컬 Docker에 이미 동일한 이미지가 존재하면 `docker pull`을 건너뛰며, `--output` 디렉토리에 이미 동일한 `.tar` 파일(`gitlab-<ee|ce>-<version>.tar`)이 존재하면 `docker save`를 건너뜁니다.
   * 생성된 `.tar` 파일의 소유권을 현재 실행 사용자의 UID/GID로 자동 변경합니다.
4. **Docker 미설치 환경 대응**
   * 시스템에 Docker가 설치되어 있지 않은 경우, 대화형 확인을 거쳐 패키지 관리자(`apt`, `dnf`, `yum`)를 통한 Docker 자동 설치 및 데몬 기동을 지원합니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--version <ver1[,ver2...]>` | 선택* | 다운로드할 GitLab 버전 지정 (콤마로 다중 지정 가능, `--file`과 최소 택 1 필수) |
| `--file <file-path>` | 선택* | GitLab 버전 목록이 기록된 텍스트 파일 경로 (`--version`과 최소 택 1 필수) |
| `--output <dir-path>` | 선택 | 다운로드한 이미지를 `gitlab-<edition>-<version>.tar` 파일로 저장할 디렉토리 경로 (생략 시 `docker pull`만 수행) |
| `--help` | 선택 | 도움말을 출력하고 종료합니다. |

---

## 🚀 사용 예시

```bash
# 1) 특정 GitLab EE/CE 버전 이미지를 로컬 Docker에 다운로드
./pull-gitlab-images --version 17.4.2-ee.0,17.5.1-ce.0

# 2) 버전 목록 파일을 읽어 이미지를 다운로드하고 /opt/gitlab-archives에 .tar 파일로 저장
./pull-gitlab-images --file ./versions.txt --output /opt/gitlab-archives
```
