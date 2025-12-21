@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM NOTE: Keep everything ASCII before chcp to avoid mojibake/parse issues.
chcp 65001 > nul

REM =======================================
REM @auther : parkjunhong77@gmail.com
REM @title  : git merge from A to B
REM @license: Apache License 2.0
REM @since  : 2020-08-18
REM =======================================

REM ---------------------------------------------------
REM Subroutines first. Main starts at :MAIN
REM ---------------------------------------------------
goto :MAIN

:READLINE
REM Usage: call :READLINE "Prompt text" OUTVAR OUTRC
REM OUTRC: 0=ok, 130=Ctrl+C
set "PROMPT=%~1"
set "OUTVAR=%~2"
set "RCVAR=%~3"
set "TMP_IN=%TEMP%\git_merge_read_%RANDOM%_%RANDOM%.txt"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { $v = Read-Host '%PROMPT%'; Set-Content -LiteralPath '%TMP_IN%' -Value $v -NoNewline -Encoding UTF8; exit 0 } catch [System.Management.Automation.Host.ControlCException] { exit 130 }" ^
  >nul 2>&1

set "RC=%errorlevel%"

set "VAL="
if exist "%TMP_IN%" (
  set /p "VAL=" < "%TMP_IN%"
  del /q "%TMP_IN%" >nul 2>&1
)

set "%OUTVAR%=%VAL%"
set "%RCVAR%=%RC%"
exit /b 0

:SHOW_LIST
for /L %%i in (1,1,%TOTAL_BRANCHES%) do (
  if "!BRANCH[%%i]!"=="%ORIG_BRANCH%" (
    echo  [%%i] !BRANCH[%%i]!  ^<-- ^(현재^)
  ) else (
    echo  [%%i] !BRANCH[%%i]!
  )
)
exit /b 0

:IS_NUMBER
set "VAL=%~1"
set "OUTVAR=%~2"
set "ISNUM=1"
if "%VAL%"=="" set "ISNUM=0"
for /f "delims=0123456789" %%A in ("%VAL%") do set "ISNUM=0"
set "%OUTVAR%=%ISNUM%"
exit /b 0

:USER_EXIT
echo.
echo [Cancel] 사용자가 작업을 취소했습니다. 종료합니다.
exit /b 0

:ERROR_EXIT
echo.
echo [Error] 오류가 발생하여 작업이 중단되었습니다.
exit /b 1

REM ---------------------------------------------------
REM Main
REM ---------------------------------------------------
:MAIN

REM 한글 파일명 깨짐 방지 (repo local)
git config --local core.quotepath false >nul 2>&1

REM 줄바꿈 변수(LF) 정의 (빈 줄 2개는 필수)
set LF=^


REM ====================================================
REM 0) 현재 브랜치
REM ====================================================
set "ORIG_BRANCH="
for /f "delims=" %%i in ('git branch --show-current 2^>nul') do set "ORIG_BRANCH=%%i"
if "%ORIG_BRANCH%"=="" (
  echo [오류] 현재 git 저장소가 아니거나 브랜치를 찾을 수 없습니다.
  goto ERROR_EXIT
)

REM ====================================================
REM 1) 로컬 브랜치 목록
REM ====================================================
set "IDX=0"
for /f "usebackq delims=" %%a in (`git branch --format="%%(refname:short)" 2^>nul`) do (
  set /a IDX+=1
  set "BRANCH[!IDX!]=%%a"
)
set "TOTAL_BRANCHES=%IDX%"
if %TOTAL_BRANCHES% LSS 1 (
  echo [오류] 브랜치 목록을 가져올 수 없습니다.
  goto ERROR_EXIT
)

REM ====================================================
REM 1단계: Source 브랜치 선택
REM ====================================================
:STEP1
cls
echo ==========================================
echo  GIT MERGE HELPER (Windows)
echo ==========================================
echo  * 현재 위치: %ORIG_BRANCH%
echo.
echo  [1단계] '가져올(Source)' 브랜치를 선택하세요.
echo ------------------------------------------
call :SHOW_LIST
echo ------------------------------------------

:STEP1_RETRY
set "SRC_NUM="
set "INRC="
call :READLINE "번호 입력 [1 ~ %TOTAL_BRANCHES%]" SRC_NUM INRC

if "%INRC%"=="130" goto USER_EXIT

if "%SRC_NUM%"=="" (
  echo.
  echo [알림] 브랜치 번호를 입력해주세요.
  goto STEP1_RETRY
)

call :IS_NUMBER "%SRC_NUM%" ISNUM
if "%ISNUM%"=="0" (
  echo [오류] 숫자만 입력해주세요.
  goto STEP1_RETRY
)

if %SRC_NUM% LSS 1 (
  echo [오류] 범위 밖의 번호입니다. 다시 입력해주세요.
  goto STEP1_RETRY
)
if %SRC_NUM% GTR %TOTAL_BRANCHES% (
  echo [오류] 범위 밖의 번호입니다. 다시 입력해주세요.
  goto STEP1_RETRY
)

set "SRC_BRANCH=!BRANCH[%SRC_NUM%]!"

REM ====================================================
REM 2단계: Target 브랜치 선택
REM ====================================================
:STEP2
cls
echo ==========================================
echo  GIT MERGE HELPER (Windows)
echo ==========================================
echo  * Source : %SRC_BRANCH%
echo.
echo  [2단계] '적용할(Target)' 브랜치를 선택하세요.
echo ------------------------------------------
call :SHOW_LIST
echo ------------------------------------------

:STEP2_RETRY
set "TGT_NUM="
set "INRC="
call :READLINE "번호 입력 [1 ~ %TOTAL_BRANCHES%]" TGT_NUM INRC

if "%INRC%"=="130" goto USER_EXIT

if "%TGT_NUM%"=="" (
  echo.
  echo [알림] 브랜치 번호를 입력해주세요.
  goto STEP2_RETRY
)

call :IS_NUMBER "%TGT_NUM%" ISNUM
if "%ISNUM%"=="0" (
  echo [오류] 숫자만 입력해주세요.
  goto STEP2_RETRY
)

if %TGT_NUM% LSS 1 (
  echo [오류] 범위 밖의 번호입니다. 다시 입력해주세요.
  goto STEP2_RETRY
)
if %TGT_NUM% GTR %TOTAL_BRANCHES% (
  echo [오류] 범위 밖의 번호입니다. 다시 입력해주세요.
  goto STEP2_RETRY
)

set "TARGET_BRANCH=!BRANCH[%TGT_NUM%]!"

if "%SRC_BRANCH%"=="%TARGET_BRANCH%" (
  echo.
  echo [오류] Source와 Target 브랜치가 같습니다. Target을 다시 선택하세요.
  pause
  goto STEP2
)

REM ====================================================
REM 3단계: 요약 출력 후 사용자 입력
REM ====================================================
:STEP3
cls
echo ==========================================
echo  작업 요약
echo ==========================================
echo  1. Source : %SRC_BRANCH% ^(Pull^)
echo  2. Target : %TARGET_BRANCH% ^(Pull^)
echo  3. Action : %SRC_BRANCH% -^> %TARGET_BRANCH% ^(Merge ^& Push^)
echo  4. Return : %ORIG_BRANCH%
echo ==========================================
echo  ^(진행하려면 Enter, 중단하려면 Ctrl+C^)

set "CONFIRM="
set "INRC="
call :READLINE "진행하시겠습니까? [Enter: Yes]" CONFIRM INRC
if "%INRC%"=="130" goto USER_EXIT

echo.
echo ^> ^> ^> git checkout "%SRC_BRANCH%"
git checkout "%SRC_BRANCH%"
if %errorlevel% neq 0 goto ERROR_EXIT

echo ^> ^> ^> git pull
git pull
if %errorlevel% neq 0 goto ERROR_EXIT

echo.
echo ^> ^> ^> git checkout "%TARGET_BRANCH%"
git checkout "%TARGET_BRANCH%"
if %errorlevel% neq 0 goto ERROR_EXIT

echo ^> ^> ^> git pull
git pull
if %errorlevel% neq 0 goto ERROR_EXIT

echo.
echo ^> ^> ^> git merge "%SRC_BRANCH%"
git merge "%SRC_BRANCH%"
set "MERGE_RC=%errorlevel%"

set "HAS_CONFLICT="
for /f "delims=" %%U in ('git ls-files -u 2^>nul') do set "HAS_CONFLICT=1"

if defined HAS_CONFLICT (
  echo.
  echo ########################################################
  echo [!] 병합 충돌^(Conflict^) 발생!
  echo ########################################################
  echo 1. 충돌된 파일을 열어 수정하세요.
  echo 2. 수정 후 'git add' 및 'git commit'을 완료하세요.
  echo 3. 완료되었으면 이 창에서 [Enter]를 누르세요.
  echo    ^(작업을 취소하려면 Ctrl+C^)
  echo ########################################################
  set "DUMMY="
  set "INRC="
  call :READLINE "완료 후 Enter 키 입력" DUMMY INRC
  if "%INRC%"=="130" goto USER_EXIT
) else (
  if not "%MERGE_RC%"=="0" (
    echo.
    echo [Error] 병합에 실패했습니다. 충돌은 없지만 병합이 실패했습니다. 위 로그를 확인하세요.
    goto ERROR_EXIT
  )
)

echo.
echo ^> ^> ^> git push
git push
if %errorlevel% neq 0 (
  echo [오류] Push 중 문제가 발생했습니다.
)

echo.
echo ^> ^> ^> git checkout "%ORIG_BRANCH%"
git checkout "%ORIG_BRANCH%"

echo.
echo [완료] 작업이 끝났습니다.
exit /b 0
