# nexus

Sonatype Nexus Repository 다중 인스턴스 설치, 데이터 아카이빙/내보내기, 마이그레이션/임포트, 스냅샷 정리 및 자산 분석을 지원하는 전문 CLI 운영 툴체인 디렉토리입니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | 설명 | 지원 기능 |
| :--- | :--- | :--- |
| [`nexus-installer`](./nexus-installer/README.md) | Nexus Repository 설치 및 다중 인스턴스/언인스톨 관리 도구 | 원격/로컬 패키지 설치, systemd 등록, 다중 인스턴스 격리, 대화형 완전 삭제 |
| [`nexus-maven-export`](./nexus-maven-export/README.md) | Nexus Maven 아티팩트 일괄 내보내기/백업 도구 | 대용량 저장소 안전 순회, 다중 저장소 지정, 원본 계층 경로 보존 |
| [`nexus-maven-import`](./nexus-maven-import/README.md) | Nexus Maven 아티팩트 일괄 업로드 및 마이그레이션 도구 | 저장소 1:1 매핑, 원격 중복 사전 검증, 실패 시 자동 재시도, 체크섬 필터링 |
| [`nexus-snapshot-manager`](./nexus-snapshot-manager/README.md) | Nexus Maven SNAPSHOT 아티팩트 선별 정리 도구 | 대화형/옵션형 대상 선택, 버전별 타임스탬프 빌드 보관 개수 제어 |
| [`nexus-assets-analyze`](./nexus-assets-analyze/README.md) | Nexus 저장소 Asset 통계 및 확장자 분포 분석 도구 | 자산 전수 조사, 총 용량/건수 요약, 확장자별 분포 리포트 생성 |

---

## 📁 디렉토리 구조

```plaintext
nexus/
├── README.md
├── nexus-assets-analyze/
│   ├── README.md
│   ├── nexus-assets-analyze
│   └── nexus-assets-analyze.completion
├── nexus-installer/
│   ├── README.md
│   ├── nexus-installer
│   └── nexus-installer.completion
├── nexus-maven-export/
│   ├── README.md
│   ├── nexus-maven-export
│   └── nexus-maven-export.completion
├── nexus-maven-import/
│   ├── README.md
│   ├── nexus-maven-import
│   └── nexus-maven-import.completion
└── nexus-snapshot-manager/
    ├── README.md
    ├── nexus-snapshot-manager
    └── nexus-snapshot-manager.completion
```

---

## 🛠️ 공통 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 환경(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../utils/scriptctl/scriptctl install --script ./nexus-installer/nexus-installer --target local
../utils/scriptctl/scriptctl install --script ./nexus-maven-export/nexus-maven-export --target local
../utils/scriptctl/scriptctl install --script ./nexus-maven-import/nexus-maven-import --target local
../utils/scriptctl/scriptctl install --script ./nexus-snapshot-manager/nexus-snapshot-manager --target local
../utils/scriptctl/scriptctl install --script ./nexus-assets-analyze/nexus-assets-analyze --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../utils/scriptctl/scriptctl install --script ./nexus-installer/nexus-installer --target global
../utils/scriptctl/scriptctl install --script ./nexus-maven-export/nexus-maven-export --target global
../utils/scriptctl/scriptctl install --script ./nexus-maven-import/nexus-maven-import --target global
../utils/scriptctl/scriptctl install --script ./nexus-snapshot-manager/nexus-snapshot-manager --target global
../utils/scriptctl/scriptctl install --script ./nexus-assets-analyze/nexus-assets-analyze --target global
```
