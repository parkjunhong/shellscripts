# 🔑 letsencrypt (SSH RSA 공개키)

Let's Encrypt SSL/TLS 와일드카드 인증서의 자동 발급 및 갱신 후 사내 대상 서버들에 인증서 파일을 무인 자동 배포하기 위한 **배포 자동화 에이전트 전용 SSH RSA 공개키**입니다.

---

## 📋 키 메타데이터

* **식별자**: `letsencrypt`
* **키 파일**: `letsencrypt.pub`
* **키 알고리즘**: `ssh-rsa` (2048-bit)
* **주요 용도**: Let's Encrypt 인증서 동기화 봇 / rsync / SCP 접속 허용

---

## 🔒 보안 권장사항
* 대상 서버의 `~/.ssh/authorized_keys` 등록 시, 특정 IP 대역에서만 접속할 수 있도록 `from="..."` 지시자를 결합하여 사용하는 것을 권장합니다.
