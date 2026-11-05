# 🚀 install-temurin-25-jdk

Eclipse Adoptium 공식 저장소에서 **Eclipse Temurin 25 JDK**를 시스템에 설치하는 자동화 스크립트입니다.

---

## ✨ 주요 특징

1. **Adoptium 공식 패키지 저장소 자동 등록**:
   * **RPM 계열 (Rocky, RHEL, CentOS Stream)**: Adoptium RPM GPG 키 및 YUM 저장소(`/etc/yum.repos.d/adoptium.repo`) 등록 후 `temurin-25-jdk` 패키지 설치
   * **DEB 계열 (Ubuntu, Debian)**: Adoptium 공식 APT GPG 키링(`/etc/apt/keyrings/adoptium.gpg`) 및 APT 소스 리스트(`/etc/apt/sources.list.d/adoptium.list`) 등록 후 패키지 설치
   * **macOS**: Homebrew Cask(`temurin@25` 또는 최신 temurin) 설치 지원
2. **다중 Java 버전 연동**:
   * 설치 완료 후 `update-java-config` 도구와 연계하여 시스템 기본 Java 런타임을 간편하게 전환할 수 있습니다.

---

## ⚙️ 사용법

### 1. `sciectl`을 통한 실행
```bash
sciectl install --installer install-temurin-25-jdk
```

### 2. 단독 직접 실행
```bash
./install-temurin-25-jdk
```

---

## 📋 시스템 요구사항
* `sudo` 관리자 권한
* `curl`, `gpg` 유틸리티
