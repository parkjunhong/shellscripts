@echo off
setlocal EnableDelayedExpansion
chcp 65001 > nul

:: =======================================
:: @author    : parkjunhong77@gmail.com
:: @title     : migration-init-scheme.bat
:: @license   : Apache License 2.0
:: @since     : 2026-01-31
:: @desc      : Add 'DROP TABLE IF EXISTS' statement before 'CREATE TABLE'
:: =======================================

:: ------------------------------------------------------------------------------
:: 1. Variables & Constants
:: ------------------------------------------------------------------------------
set "SRC_SQL="
set "INIT_SQL="
set "FORCE_OVERWRITE=false"

:: ANSI Color Code
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

if "%SRC_SQL%"=="" (
    call :Help "Input file is required. Use -s or --src-sql."
    exit /b 1
)
if not exist "%SRC_SQL%" (
    call :Help "Source file '%SRC_SQL%' does not exist."
    exit /b 1
)
if "%INIT_SQL%"=="" (
    call :Help "Output file is required. Use -i or --init-sql."
    exit /b 1
)

if exist "%INIT_SQL%" (
    if "%FORCE_OVERWRITE%"=="true" (
        echo %YELLOW%File '%INIT_SQL%' exists. Overwriting due to --force-overwrite flag.%NC%
    ) else (
        set /p "RESPONSE=%YELLOW%File '%INIT_SQL%' already exists. Overwrite? [Y/n] (default: Y): %NC%"
        if "!RESPONSE!"=="" set "RESPONSE=y"
        if /i "!RESPONSE!"=="n" ( echo Operation cancelled by user. & exit /b 0 )
        if /i "!RESPONSE!"=="no" ( echo Operation cancelled by user. & exit /b 0 )
        echo Overwriting file...
    )
)

:: ------------------------------------------------------------------------------
:: 4. Execution (Processing File)
:: ------------------------------------------------------------------------------

echo %GREEN%Processing SQL file...%NC%

set "PS_TEMP=%TEMP%\migration_%RANDOM%.ps1"

:: [수정됨] 괄호 블록을 제거하고 한 줄씩 쓰기(>>) 방식으로 변경하여 파싱 오류 원천 차단
echo $src = '%SRC_SQL%' > "%PS_TEMP%"
echo $dest = '%INIT_SQL%' >> "%PS_TEMP%"
echo Get-Content -Path $src -Encoding UTF8 ^| ForEach-Object { >> "%PS_TEMP%"
echo     if ($_ -match 'CREATE TABLE') { >> "%PS_TEMP%"
echo         $parts = $_.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries) >> "%PS_TEMP%"
echo         if ($parts.Length -ge 3) { >> "%PS_TEMP%"
echo             $tableName = $parts[2] >> "%PS_TEMP%"
echo             $tableName = $tableName.Replace('(', '') >> "%PS_TEMP%"
echo             Write-Output '' >> "%PS_TEMP%"
echo             Write-Output '-- =================================' >> "%PS_TEMP%"
echo             Write-Output ('DROP TABLE IF EXISTS ' + $tableName + ';') >> "%PS_TEMP%"
echo         } >> "%PS_TEMP%"
echo     } >> "%PS_TEMP%"
echo     Write-Output $_ >> "%PS_TEMP%"
echo } ^| Set-Content -Path $dest -Encoding UTF8 >> "%PS_TEMP%"

:: 임시 스크립트 실행
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_TEMP%"

:: 실행 결과 확인 및 임시 파일 삭제
if %errorlevel% equ 0 (
    if exist "%PS_TEMP%" del "%PS_TEMP%"
    echo %GREEN%Success! Migration SQL saved to: %INIT_SQL%%NC%
    exit /b 0
) else (
    if exist "%PS_TEMP%" del "%PS_TEMP%"
    call :Help "Failed to process the SQL file."
    exit /b 1
)

:: ------------------------------------------------------------------------------
:: 5. Helper Functions
:: ------------------------------------------------------------------------------

:CallHelp
call :Help
exit /b 0

:Help
set "cause=%~1"
setlocal
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
endlocal
exit /b
