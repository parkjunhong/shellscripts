@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM NOTE: Keep everything ASCII before chcp to avoid mojibake/parse issues.
chcp 65001 > nul

:: ===================================================
::  Git Commit & Push Helper Script
:: ===================================================
::  - 제목(필수) + 본문(선택, 여러 줄) 입력 후
::    git add . -> git commit -> git push
::
::  - 입력 안내
::    * 제목을 입력하고 엔터를 누르세요.
::    * 본문은 한 줄씩 입력하고 엔터를 누르면 줄바꿈됩니다.
::    * 입력을 마치려면 [빈 줄에서 엔터]를 누르세요.
::
::  - 안정성(중요)
::    * 일부 환경(PowerShell/Windows Terminal + UTF-8)에서 set /p가
::      빈 Enter에도 errorlevel=1을 남기는 케이스가 있어,
::      본문 입력에서는 "빈 Enter 종료"를 최우선으로 처리합니다.
::
::  - 요구사항
::    1) commit 할 게 없으면 [Skip] 출력 후 push 단계 진행
::    2) push 할 게 없으면 [Skip] 출력 후 정상 종료
::       (Everything up-to-date)
:: ===================================================

REM 한글 파일명 깨짐 방지 (repo local)
git config --local core.quotepath false > nul 2>&1

REM 0) 줄바꿈 변수(LF) 정의 (아래의 '빈 줄 2개'는 필수)
set LF=^


REM 줄바꿈 변수 정의 끝

echo.
echo [입력] 커밋 메시지를 작성하세요.
echo ---------------------------------------------------
echo  * 제목을 입력하고 엔터를 누르세요.
echo  * 본문은 한 줄씩 입력하고 엔터를 누르면 줄바꿈됩니다.
echo  * 입력을 마치려면 [빈 줄에서 엔터]를 누르세요.
echo ---------------------------------------------------

REM 1) 제목 입력 (필수)
:ASK_SUBJECT
ver > nul
set "COMMIT_SUBJECT="
set /p "COMMIT_SUBJECT=제목 > "

REM Ctrl+Z/입력 스트림 종료 등
if errorlevel 1 (
  if not defined COMMIT_SUBJECT goto :EXIT
)

if not defined COMMIT_SUBJECT (
  echo 제목은 필수입니다. 다시 입력해주세요.
  goto :ASK_SUBJECT
)

REM 2) 본문 입력 (선택)
set "COMMIT_BODY="
echo 본문 (종료: 빈 Enter)

:ASK_BODY_LOOP
ver > nul
set "BODY_LINE="
set /p "BODY_LINE=> "

REM [방어] errorlevel=1이어도 "빈 Enter"면 정상 종료
if errorlevel 1 (
  if not defined BODY_LINE goto :PREVIEW
  goto :EXIT
)

if not defined BODY_LINE goto :PREVIEW

if not defined COMMIT_BODY (
  set "COMMIT_BODY=!BODY_LINE!"
) else (
  set "COMMIT_BODY=!COMMIT_BODY!!LF!!BODY_LINE!"
)
goto :ASK_BODY_LOOP

REM ---------------------------------------------------
REM 3) Commit Message Preview
REM ---------------------------------------------------
:PREVIEW
echo.
echo ---------------------------------------------------
echo [Commit Message]
echo 제목: !COMMIT_SUBJECT!
echo 본문:
echo.
if defined COMMIT_BODY (
  echo !COMMIT_BODY!
)
echo ---------------------------------------------------

REM Git 명령에서 큰따옴표 이스케이프 ( " -> \" )
set "SAFE_SUBJECT=!COMMIT_SUBJECT:"=\"!"
if defined COMMIT_BODY set "SAFE_BODY=!COMMIT_BODY:"=\"!"

REM 임시 로그 파일
set "TMP_COMMIT_LOG=%TEMP%\git_commit_%RANDOM%_%RANDOM%.log"
set "TMP_PUSH_LOG=%TEMP%\git_push_%RANDOM%_%RANDOM%.log"

REM ---------------------------------------------------
REM 4) Commit (변경사항 없으면 commit 자체를 수행하지 않음)
REM ---------------------------------------------------
echo.
echo [Committing...]

git add -A

REM staged 변경사항 존재 여부 확인
git diff --cached --quiet
set "DIFF_RC=%errorlevel%"

if "%DIFF_RC%"=="0" (
  REM staged 변경사항 없음 => commit skip
  git status > "!TMP_COMMIT_LOG!" 2>&1
  type "!TMP_COMMIT_LOG!"
  echo.
  echo [Skip] 커밋할 변경 사항이 없어 커밋을 건너뜁니다.
  goto :DO_PUSH
)

if not "%DIFF_RC%"=="1" (
  echo [Error] 커밋 준비 단계에서 오류가 발생했습니다. (git diff --cached)
  goto :CLEANUP_ERROR
)

REM staged 변경사항 있음 => commit 수행
if defined COMMIT_BODY (
  git commit -m "!SAFE_SUBJECT!" -m "!SAFE_BODY!" > "!TMP_COMMIT_LOG!" 2>&1
) else (
  git commit -m "!SAFE_SUBJECT!" > "!TMP_COMMIT_LOG!" 2>&1
)
set "COMMIT_RC=%errorlevel%"

type "!TMP_COMMIT_LOG!"

if not "%COMMIT_RC%"=="0" (
  echo.
  echo [Error] 커밋에 실패했습니다. 위 로그를 확인하세요.
  goto :CLEANUP_ERROR
)

echo.
echo [Success] 커밋이 완료되었습니다.

REM ---------------------------------------------------
REM 5) Push (commit skip이어도 항상 진행)
REM ---------------------------------------------------
:DO_PUSH
echo.
echo [Pushing...]

git push > "!TMP_PUSH_LOG!" 2>&1
set "PUSH_RC=%errorlevel%"

type "!TMP_PUSH_LOG!"

REM "푸시할 게 없음" 판정
findstr /i /c:"Everything up-to-date" /c:"Everything up to date" "!TMP_PUSH_LOG!" > nul
set "UPTODATE_RC=%errorlevel%"

if "%UPTODATE_RC%"=="0" (
  echo.
  echo [Skip] 푸시할 변경 사항이 없습니다.
  echo.
  echo [Success] 성공적으로 푸시되었거나 최신 상태입니다.
  goto :CLEANUP_OK
)

if not "%PUSH_RC%"=="0" (
  echo.
  echo [Error] 푸시에 실패했습니다. 위 로그를 확인하세요.
  goto :CLEANUP_ERROR
)

echo.
echo [Success] 성공적으로 푸시되었습니다.
goto :CLEANUP_OK

REM ---------------------------------------------------
REM Cleanup & Exit
REM ---------------------------------------------------
:CLEANUP_OK
del /q "!TMP_COMMIT_LOG!" > nul 2>&1
del /q "!TMP_PUSH_LOG!" > nul 2>&1
exit /b 0

:CLEANUP_ERROR
del /q "!TMP_COMMIT_LOG!" > nul 2>&1
del /q "!TMP_PUSH_LOG!" > nul 2>&1
pause
exit /b 1

:EXIT
echo.
echo [Cancel] 작업을 취소하고 종료합니다.
exit /b 1
