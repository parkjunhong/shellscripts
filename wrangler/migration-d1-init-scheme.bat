@echo off
setlocal EnableDelayedExpansion
chcp 65001 > nul

:: =======================================
:: @author    : parkjunhong77@gmail.com
:: @title     : migration-init-scheme.bat
:: @license   : Apache License 2.0
:: @since     : 2026-01-31
:: @desc      : Add 'DROP TABLE IF EXISTS' statement before 'CREATE TABLE'
:: @installation : 
::   1. Add the directory containing this file to your PATH environment variable.
:: =======================================

:: ------------------------------------------------------------------------------
:: 1. Variables & Constants
:: ------------------------------------------------------------------------------
set "SRC_SQL="
set "INIT_SQL="
set "FORCE_OVERWRITE=false"

:: ANSI Color Code 설정을 위한 ESC 문자 정의
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"

set "RED=%ESC%[0;31m"
set "GREEN=%ESC%[0;32m"
set "YELLOW=%ESC%[1;33m"
set "BLUE=%ESC%[0;34m"
set "NC=%ESC%[0m"

:: ------------------------------------------------------------------------------
:: 2. Argument Parsing
:: ------------------------------------------------------------------------------
:ParseArgs
if "%~1"=="" goto :EndParseArgs
if /i "%~1"=="-h" goto :CallHelp
if /i "%~1"=="--help" goto :CallHelp
if /i "%~1"=="-f" (
    set "FORCE_OVERWRITE=true"
    shift
    goto :ParseArgs
)
if /i "%~1"=="--force-overwrite" (
    set "FORCE_OVERWRITE=true"
    shift
    goto :ParseArgs
)
if /i "%~1"=="-s" (
    set "SRC_SQL=%~2"
    shift
    shift
    goto :ParseArgs
)
if /i "%~1"=="--src-sql" (
    set "SRC_SQL=%~2"
    shift
    shift
    goto :ParseArgs
)
if /i "%~1"=="-i" (
    set "INIT_SQL=%~2"
    shift
    shift
    goto :ParseArgs
)
if /i "%~1"=="--init-sql" (
    set "INIT_SQL=%~2"
    shift
    shift
    goto :ParseArgs
)

call :Help "Unknown parameter passed: %~1"
exit /b 1

:EndParseArgs

:: ------------------------------------------------------------------------------
:: 3. Validation
:: ------------------------------------------------------------------------------

:: 1) 입력 파일 파라미터 확인
if "%SRC_SQL%"=="" (
    call :Help "Input file is required. Use -s or --src-sql."
    exit /b 1
)

:: 2) 입력 파일 존재 여부 확인
if not exist "%SRC_SQL%" (
    call :Help "Source file '%SRC_SQL%' does not exist."
    exit /b 1
)

:: 3) 출력 파일 파라미터 확인
if "%INIT_SQL%"=="" (
    call :Help "Output file is required. Use -i or --init-sql."
    exit /b 1
)

:: 4) 출력 파일 덮어쓰기 확인
if exist "%INIT_SQL%" (
    if "%FORCE_OVERWRITE%"=="true" (
        echo %YELLOW%File '%INIT_SQL%' exists. Overwriting due to --force-overwrite flag.%NC%
    ) else (
        :AskOverwrite
        set /p "RESPONSE=%YELLOW%File '%INIT_SQL%' already exists. Overwrite? [Y/n] (default: Y): %NC%"
        
        :: Default to Y if empty
        if "!RESPONSE!"=="" set "RESPONSE=y"
        
        :: Check for No
        if /i "!RESPONSE!"=="n" (
            echo Operation cancelled by user.
            exit /b 0
        )
        if /i "!RESPONSE!"=="no" (
            echo Operation cancelled by user.
            exit /b 0
        )
        
        echo Overwriting file...
    )
)

:: ------------------------------------------------------------------------------
:: 4. Execution (Processing File)
:: ------------------------------------------------------------------------------

echo %GREEN%Processing SQL file...%NC%

:: PowerShell을 사용하여 AWK 로직 대체
:: 로직: 파일을 읽어서 줄 단위로 처리 -> CREATE TABLE 정규식 매칭 -> 테이블명 추출 -> DROP 구문 선행 출력
:: 주의: 배치 파일 내에서 특수문자 처리를 위해 PowerShell Command를 신중히 구성함

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$src = '%SRC_SQL%';" ^
    "$dest = '%INIT_SQL%';" ^
    "Get-Content -Path $src -Encoding UTF8 | ForEach-Object {" ^
    "    if ($_ -match '^CREATE TABLE') {" ^
    "        $parts = $_.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries);" ^
    "        if ($parts.Length -ge 3) {" ^
    "            $tableName = $parts[2];" ^
    "            $tableName = $tableName.Replace('(', '');" ^
    "            Write-Output '';" ^
    "            Write-Output '-- =================================';" ^
    "            Write-Output ('DROP TABLE IF EXISTS ' + $tableName + ';');" ^
    "        }" ^
    "    }" ^
    "    Write-Output $_;" ^
    "} | Set-Content -Path $dest -Encoding UTF8"

:: ------------------------------------------------------------------------------
:: 5. Finalize
:: ------------------------------------------------------------------------------

if %errorlevel% equ 0 (
    echo %GREEN%Success! Migration SQL saved to: %INIT_SQL%%NC%
    exit /b 0
) else (
    call :Help "Failed to process the SQL file."
    exit /b 1
)

:: ------------------------------------------------------------------------------
:: 함수 정의 (Helper Functions)
:: ------------------------------------------------------------------------------

:CallHelp
call :Help
exit /b 0

:Help
::
:: 스크립트 사용법 및 오류 발생 시 콜스택 정보를 출력합니다.
::
:: @param %1 {string} 오류 원인 (선택 사항)
:: @param %2 {number} 오류 발생 라인 번호 (선택 사항 - 배치에서는 정확한 라인 추적이 어려워 생략 가능)
::
:: @return 사용법 및 디버깅 정보 출력
::
set "cause=%~1"
setlocal
    set "indent=10"
    
    if not "%cause%"=="" (
        echo.
        echo ================================================================================
        echo  - filename  : %~nx0
        echo  - cause     : %cause%
        echo ================================================================================
    )
    
    echo.
    echo %BLUE%Usage:%NC% %~nx0 [OPTIONS]
    echo.
    echo %YELLOW%Options:%NC%
    echo   -s, --src-sql ^<file^>       Input SQL file path (Required)
    echo   -i, --init-sql ^<file^>      Output SQL file path (Required)
    echo   -f, --force-overwrite      Overwrite output file without prompting if it exists
    echo   -h, --help                 Show this help message
    echo.
    echo %YELLOW%Example:%NC%
    echo   %~nx0 -s original.sql -i migration.sql -f
endlocal
exit /b
