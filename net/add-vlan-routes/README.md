# 🛣️ add-vlan-routes

Linux 배포판(NetworkManager, Netplan, systemd-networkd, systemd 서비스) 및 macOS 환경에서 물리 네트워크 인터페이스를 자동 식별하고, 지정된 VLAN 대역으로 향하는 **영구(Permanent) 정적 라우팅(Static Route)** 규칙을 안전하게 추가·삭제·관리하는 크로스 플랫폼 CLI 도구입니다.

---

## ✨ 주요 특징

1. **광범위한 크로스 플랫폼 및 네트워크 스택 지원**
   * **Linux**: RHEL / Rocky / CentOS / AlmaLinux / Oracle Linux (7+), Ubuntu / Debian, Arch / Manjaro, SUSE, Alpine 등 지원.
   * **네트워크 백엔드 자동 감지**: `nmcli` (NetworkManager), `netplan`, `systemd-networkd`, 네트워크 스크립트 fallback 및 `systemd` 전용 서비스 자동 생성 지원.
   * **macOS**: `networksetup` 및 커널 라우팅 테이블 연동 지원.
   * **Windows 호환성**: 동일 디렉토리 내에 `add-vlan-routes.bat` 배치 파일이 함께 제공되어 Windows 환경 라우팅도 지원.
2. **동적 물리 인터페이스 및 기본 게이트웨이 식별**
   * 현재 트래픽이 나가는 기본 게이트웨이 및 물리 인터페이스를 자동 감지하여 라우팅 대상을 정밀하게 산출합니다.
3. **영구(Permanent) 저장 및 즉시 반영**
   * 재부팅 후에도 설정이 영구 보존되도록 각 OS/배포판의 네트워크 설정 파일에 기록하며, 현재 커널 라우팅 테이블에도 즉시 반영합니다.
4. **시뮬레이션 모드 (`--dry-run`)**
   * 실제 시스템 네트워크 설정을 변경하기 전에 적용 예정인 인터페이스, 게이트웨이, 라우팅 명령어를 미리 안전하게 확인할 수 있습니다.
5. **지능형 Bash 자동 완성 (`add-vlan-routes.completion`)**
   * 옵션 및 네트워크 대역 파라미터 자동 완성을 제공합니다.

---

## ⚙️ 파라미터 명세

```bash
add-vlan-routes [옵션]
```

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--add-vlan-networks <CIDR>` | 선택 | 추가할 대상 VLAN 네트워크 대역 (콤마(`,`) 구분 다중 지정 가능) |
| `--remove-vlan-networks <CIDR>` | 선택 | 제거할 대상 VLAN 네트워크 대역 (콤마(`,`) 구분 다중 지정 가능) |
| `--dry-run` | 선택 | 시스템 구성을 변경하지 않고 작업 계획만 시뮬레이션 출력 |
| `--help` | 선택 | 도움말 메시지 출력 및 종료 |

---

## 🚀 사용 예시

```bash
# 1) VLAN 정적 라우팅 추가 시뮬레이션 (Dry-Run)
./add-vlan-routes --dry-run --add-vlan-networks 192.168.100.0/24,10.50.0.0/16

# 2) 단일 VLAN 대역 영구 정적 라우팅 추가
sudo ./add-vlan-routes -a 192.168.100.0/24

# 3) 복수 VLAN 대역 영구 정적 라우팅 일괄 추가
sudo ./add-vlan-routes -a 192.168.100.0/24,192.168.200.0/24,10.20.0.0/16

# 4) 등록된 VLAN 대역 정적 라우팅 삭제
sudo ./add-vlan-routes -r 192.168.100.0/24

# 5) 추가 및 삭제 동시 처리
sudo ./add-vlan-routes -a 10.30.0.0/16 -r 10.20.0.0/16
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./add-vlan-routes --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./add-vlan-routes --target global
```

