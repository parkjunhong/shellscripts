# 🚀 install-htop

Linux 및 macOS 환경에서 직관적인 텍스트 기반 대화형 프로세스 뷰어인 **htop**을 설치하는 자동화 스크립트입니다.

---

## ✨ 주요 특징

1. **OS 및 패키지 관리자 자동 감지**:
   * **Ubuntu / Debian 계열**: `apt-get`을 통해 `htop` 설치
   * **RHEL / Rocky / CentOS 계열**: Fedora 공식 EPEL(Extra Packages for Enterprise Linux) RPM 저장소를 자동 등록한 후 DNF/YUM으로 설치
   * **macOS**: Homebrew(`brew install htop`)를 통해 자동 설치
2. **사전 설치 여부 검사**:
   * 시스템에 이미 `htop` 바이너리가 존재할 경우 불필요한 재설치를 건너뛰어 멱등성(Idempotency)을 보장합니다.

---

## ⚙️ 사용법

### 1. `sciectl`을 통한 실행
```bash
sciectl install --installer htop
```

### 2. 단독 직접 실행
```bash
./install-htop
```

---

## 📋 시스템 요구사항
* Linux: `root` 또는 `sudo` 권한 필요
* macOS: Homebrew 설치 필요
