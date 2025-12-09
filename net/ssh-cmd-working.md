>>>
개발 진행)

1. 설계/요구사항 정리, ssh-cmd.sh 코드 구현 <---
2. bash_completion
3. man 페이지/문서화

>>>
"추가/삭제/수정/이동" 기능에서 아래와 같이 데이터 구분(=, -)을 추가해 줘.

요청사항)

1) 추가 ( --add-connection | -a
```
[14:50:19 ] parkjunhong@ubuntu-2004:$ ./ssh-cmd -a
[INFO] 새 connection 정보를 입력합니다.
----------------------------------------------------------- <--- 추가할 것.
❓  📁  group                        [default]: 
❓  🏷  name                        : 
----------------------------------------------------------- <--- 입력이 끝난 마지막에도 추가할 것.
[directory] ~/Downloads
[14:50:24 ] parkjunhong@ubuntu-2004:$ 

2) 수정 ( --modify-connection | -m )
```
$ ./ssh-cmd -m
================================================================================
#     Group     Name           Host                     Port  User    Credential
--------------------------------------------------------------------------------
0001  default   사내 통합 ERP  erp.ymtech.co.kr         22    ymtech  ****************
0002  com#1     com            gitlab.ymtech.co.kr      22    ymtech  ****************
0003  team-1    tex            192.168.0.123            24    user    ****************
0004  xyz       gitlab         gitlab.ymtch.co.kr       22    ymtech  ****************
0005  xyz       xyz            sts.ymtech.co.kr         22    ymtech  ****************
0006  xyz       xyz-1          sts.ymtech.co.kr         22    ymtech  ****************
0007  ymtech    Repository     nexus3-int.ymtech.co.kr  22    ymtech  ****************
0008  ymtech    gitlab 서버    gitlab.ymtech.co.kr      22    ymtech  ****************
0009  ymtech-x  gitlab-x       gitlab.ymtech.co.kr      22    ymtech  ****************
================================================================================
❓  번호(#)를 선택하세요 (예: 1, 2, 3): 1
----------------------------------------------------------- <--- 추가할 것.
❓  📁  group                        [default]: 
❓  🏷  name                         [사내 통합 ERP]: 
...
----------------------------------------------------------- <--- 입력이 끝난 마지막에도 추가할 것.
$ 
```

4) 그룹 수정 (-mg)
```
$ ./ssh-cmd -mg
================================================================================
#     Group     Name           Host                     Port  User    Credential
--------------------------------------------------------------------------------
0001  default   사내 통합 ERP  erp.ymtech.co.kr         22    ymtech  ****************
0002  com#1     com            gitlab.ymtech.co.kr      22    ymtech  ****************
0003  team-1    tex            192.168.0.123            24    user    ****************
0004  xyz       gitlab         gitlab.ymtch.co.kr       22    ymtech  ****************
0005  xyz       xyz            sts.ymtech.co.kr         22    ymtech  ****************
0006  xyz       xyz-1          sts.ymtech.co.kr         22    ymtech  ****************
0007  ymtech    Repository     nexus3-int.ymtech.co.kr  22    ymtech  ****************
0008  ymtech    gitlab 서버    gitlab.ymtech.co.kr      22    ymtech  ****************
0009  ymtech-x  gitlab-x       gitlab.ymtech.co.kr      22    ymtech  ****************
================================================================================
❓  번호(#)를 선택하세요 (예: 1, 2, 3): 1
----------------------------------------------------------- <--- 추가할 것.
현재 group: default
❓  📁  새 group                    [default]: 
----------------------------------------------------------- <--- 입력이 끝난 마지막에도 추가할 것.
$ 
```


1. 코드 수정이 간단한 경우 내가 직접할 수 있도록 수정되는 코드의 "수정 전 / 수정 후" 위치와 내용을 명확히 작성해 줘.
수정할 코드가 너무 많은 경우는 전체 코드를 제공해 주고.
2. 개발요구서(SR_v1.8.2 -> SR_v1.8.3)에는 changelog 부분만 작성해 줘.
