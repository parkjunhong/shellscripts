man 페이지 파일명 뒤의 숫자 **“.1”은 “man section 번호(섹션 번호)”**를 의미합니다.
즉, 확장자가 아니라 **문서를 어떤 분류로 취급할지 지정하는 값**입니다.

아래 표 한 번 보면 바로 이해됩니다 👇

---

# 📘 **man 페이지 섹션 번호의 의미**

| 섹션 번호 | 의미 / 용도                       | 예시                                   |
| ----- | ----------------------------- | ------------------------------------ |
| **1** | 사용자 명령어(user commands)        | ls(1), ssh(1), git(1), systemctl(1)  |
| **2** | 시스템 콜(system calls)           | open(2), read(2), write(2)           |
| **3** | 라이브러리 함수(C library functions) | printf(3), malloc(3)                 |
| **4** | 디바이스/드라이버 정보(files in /dev)   | tty(4), random(4)                    |
| **5** | 파일 포맷 / 설정 파일                 | passwd(5), crontab(5), ssh_config(5) |
| **6** | 게임(games)                     | nethack(6)                           |
| **7** | 일반 문서 / 가이드 / 개념 문서           | regex(7), man-pages(7)               |
| **8** | 시스템 관리 명령어(admin commands)    | mount(8), iptables(8), systemd(8)    |

---

# 🔍 **그럼 왜 sshctl 은 “.1”인가?**

sshctl 은 “사용자가 직접 실행하는 명령(user command)”이기 때문에:

```
sshctl → section 1 → sshctl.1
```

이게 표준적인 위치입니다.

그래서 보통 설치 위치도 다음과 같습니다:

```
/usr/local/share/man/man1/sshctl.1
```

이렇게 하면:

```
man sshctl
```

만 입력하면 바로 sshctl.1 문서를 보여주게 됩니다.

---

# 📦 **만약 설정 파일을 문서화한다면?**

예를 들어 sshctl 설정파일(configuration) 문서는 **section 5**가 제일 적절합니다.

예:

```
sshctl.conf.5
man sshctl.conf
```

또는 보안 정책 등 개념 문서는 **section 7**을 씁니다.

---

# 🧠 **즉, 숫자는 확장자가 아니라 “문서의 분류 번호”이다**

* `sshctl.1` → 사용자 명령어
* `sshctl-config.5` → 설정파일 포맷
* `sshctl-security.7` → 보안 개념 문서

이렇게 자유롭게 조합해서 프로젝트 문서를 정리할 수 있습니다.

---
