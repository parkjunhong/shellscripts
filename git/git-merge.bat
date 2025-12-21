@echo off
REM =======================================
REM @auther : parkjunhong77@gmail.com
REM @title  : git merge from A to B
REM @license: Apache License 2.0
REM @since  : 2020-08-18
REM =======================================

setlocal enabledelayedexpansion
REM 한글 출력을 위해 UTF-8 코드페이지로 변경
chcp 65001 > nul

REM ====================================================
REM 0. 현재 브랜치 기억
REM ====================================================
set "ORIG_BRANCH="
for /f "delims=" %%i in ('git branch --show-current') do set "ORIG_BRANCH=%%i"

if "%ORIG_BRANCH%"=="" (
  echo [오류] 현재 git 저장소가 아니거나 브랜치를 찾을 수 없습니다.
  goto ERROR_EXIT
)

REM ====================================================
REM 1. 로컬 브랜치 목록 읽기
REM ====================================================
echo.
echo [시스템] 브랜치 목록을 불러오는 중...

set "IDX=0"
for /f "tokens=*" %%a in ('git branch --format="%%(refname:short)"') do (
  set /a IDX+=1
  set "BRANCH[!IDX!]=%%a"
)
set "TOTAL_BRANCHES=%IDX%"

if %TOTAL_BRANCHES% LSS 1 (
    echo [오류] 브랜치 목록을 가져올 수 없습니다.
    goto ERROR_EXIT
)

REM ====================================================
REM [1단계] Source 브랜치 선택
REM ====================================================
:STEP_1_START
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
echo  [q] 종료 (Exit)
echo ------------------------------------------

:RETRY_SOURCE
set "SRC_NUM="
set /p "SRC_NUM=번호 입력 [1 ~ %TOTAL_BRANCHES%] 또는 q: "

if "%SRC_NUM%"=="" (
    echo.
    echo [알림] 입력이 비어있습니다. 종료하려면 'q'를 입력하세요.
    goto RETRY_SOURCE
)

if /i "%SRC_NUM%"=="q" goto USER_EXIT
if "%SRC_NUM%"=="0" goto USER_EXIT

if %SRC_NUM% LSS 1 (
    echo [오류] 범위 밖의 숫자입니다. 다시 입력해주세요.
    goto RETRY_SOURCE
)
if %SRC_NUM% GTR %TOTAL_BRANCHES% (
    echo [오류] 범위 밖의 숫자입니다. 다시 입력해주세요.
    goto RETRY_SOURCE
)

set "SRC_BRANCH=!BRANCH[%SRC_NUM%]!"

REM ====================================================
REM [2단계] Target 브랜치 선택
REM ====================================================
:STEP_2_START
REM 화면 리프레시 추가 (사용자 요청 반영)
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
echo  [q] 종료 (Exit)
echo ------------------------------------------

:RETRY_TARGET
set "TGT_NUM="
set /p "TGT_NUM=번호 입력 [1 ~ %TOTAL_BRANCHES%] 또는 q: "

if "%TGT_NUM%"=="" (
    echo.
    echo [알림] 입력이 비어있습니다. 종료하려면 'q'를 입력하세요.
    goto RETRY_TARGET
)

if /i "%TGT_NUM%"=="q" goto USER_EXIT
if "%TGT_NUM%"=="0" goto USER_EXIT

if %TGT_NUM% LSS 1 (
    echo [오류] 잘못된 번호입니다.
    goto RETRY_TARGET
)
if %TGT_NUM% GTR %TOTAL_BRANCHES% (
    echo [오류] 잘못된 번호입니다.
    goto RETRY_TARGET
)

set "TARGET_BRANCH=!BRANCH[%TGT_NUM%]!"

if "%SRC_BRANCH%"=="%TARGET_BRANCH%" (
    echo.
    echo [오류] Source와 Target 브랜치가 같습니다. Target을 다시 선택하세요.
    pause
    goto STEP_2_START
)

REM ====================================================
REM 3. 병합 프로세스 실행
REM ====================================================
cls
echo ==========================================
echo  작업 요약
echo ==========================================
echo  1. Source : %SRC_BRANCH% (Pull)
echo  2. Target : %TARGET_BRANCH% (Pull)
echo  3. Action : %SRC_BRANCH% -^> %TARGET_BRANCH% (Merge ^& Push)
echo  4. Return : %ORIG_BRANCH%
echo ==========================================
echo  (진행하려면 엔터, 중단하려면 q 입력)
set /p "CONFIRM=진행하시겠습니까? [Enter: Yes / q: No]: "
if /i "%CONFIRM%"=="q" goto USER_EXIT

REM --- 1. Source 업데이트 ---
echo.
echo ^> ^> ^> git checkout "%SRC_BRANCH%"
git checkout "%SRC_BRANCH%"
if %errorlevel% neq 0 goto ERROR_EXIT
echo ^> ^> ^> git pull
git pull
if %errorlevel% neq 0 goto ERROR_EXIT

REM --- 2. Target 업데이트 ---
echo.
echo ^> ^> ^> git checkout "%TARGET_BRANCH%"
git checkout "%TARGET_BRANCH%"
if %errorlevel% neq 0 goto ERROR_EXIT
echo ^> ^> ^> git pull
git pull
if %errorlevel% neq 0 goto ERROR_EXIT

REM --- 3. Merge 실행 ---
echo.
echo ^> ^> ^> git merge "%SRC_BRANCH%"
git merge "%SRC_BRANCH%"

REM --- 충돌 체크 및 대기 ---
if %errorlevel% neq 0 (
  echo.
  echo ########################################################
  echo [!] 병합 충돌^(Conflict^) 발생!
  echo ########################################################
  echo 1. 충돌된 파일을 열어 수정하세요.
  echo 2. 수정 후 'git add' 및 'git commit'을 완료하세요.
  echo 3. 완료되었으면 이 창에서 [엔터]를 누르세요.
  echo ^(작업을 취소하려면 터미널을 강제로 닫거나 q를 입력하세요^)
  echo ########################################################
  set /p "CONFLICT_CONFIRM=완료 후 엔터 키 입력 (q: 스크립트 중단): "
  if /i "!CONFLICT_CONFIRM!"=="q" goto USER_EXIT
)

REM --- 4. Push ---
echo.
echo ^> ^> ^> git push
git push
if %errorlevel% neq 0 (
  echo [오류] Push 중 문제가 발생했습니다.
  goto REVERT
)

REM --- 5. 원래 브랜치 복귀 ---
:REVERT
echo.
echo ^> ^> ^> git checkout "%ORIG_BRANCH%"
git checkout "%ORIG_BRANCH%"

echo.
echo [완료] 모든 작업이 성공적으로 끝났습니다.
goto END

REM ====================================================
REM 서브루틴: 목록 출력
REM ====================================================
:SHOW_LIST
for /L %%i in (1,1,%TOTAL_BRANCHES%) do (
  if "!BRANCH[%%i]!"=="%ORIG_BRANCH%" (
    echo  [%%i] !BRANCH[%%i]!  ^<-- ^(현재^)
  ) else (
    echo  [%%i] !BRANCH[%%i]!
  )
)
exit /b

REM ====================================================
REM 종료 및 에러 처리
REM ====================================================
:USER_EXIT
echo.
echo [알림] 사용자가 작업을 취소했습니다 (종료).
exit /b 0

:ERROR_EXIT
echo.
echo [중단] 오류가 발생하여 작업이 중단되었습니다.
exit /b 1

:END
endlocal
