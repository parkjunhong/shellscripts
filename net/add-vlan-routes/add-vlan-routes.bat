@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ==============================================================================
:: [Polyglot 런처] 관리자 권한 검증 및 PowerShell 엔진 호출
:: ==============================================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ================================================================================
    echo  💡 [오류] 이 스크립트는 시스템 라우팅을 변경하므로 관리자 권한이 필요합니다.
    echo  파일을 우클릭하여 '관리자 권한으로 실행'을 선택해 주세요.
    echo ================================================================================
    pause
    exit /b 1
)

:: PowerShell 파라미터 안전 전달을 위한 ScriptBlock 기반 실행
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $lines = Get-Content '%~f0' -Encoding UTF8; $start = $lines.IndexOf('<#POWER_SHELL_START#>') + 1; $code = $lines[$start..($lines.Count-1)] -join \"`n\"; Invoke-Command -ScriptBlock ([scriptblock]::Create($code)) -ArgumentList (, $args) }" %*
exit /b %errorlevel%

<#POWER_SHELL_START#>
# =======================================
# @author : parkjunhong77@gmail.com
# @title : add vlan routes (Windows 11 Port).
# @license : Apache License 2.0
# @since : 2026-07-23
# @desc : Windows 11 호환 (PowerShell Embedded Batch)
# =======================================

# [핵심 패치 1] PowerShell의 강제 타입 캐스팅을 막기 위해 원본 그대로 수용
param($RawScriptArgs)

# [핵심 패치 2] 콤마(,) 때문에 쪼개진 인자들을 다시 완벽한 문자열로 복원 (정규화)
$ScriptArgs = @()
if ($null -ne $RawScriptArgs) {
    foreach ($a in $RawScriptArgs) {
        if ($a -is [array]) {
            $ScriptArgs += ($a -join ',')
        } else {
            $ScriptArgs += [string]$a
        }
    }
}

$FILENAME = "add-vlan-routes.bat"
$DRY_RUN = $false
$ADD_VLAN_INPUT = ""
$REMOVE_VLAN_INPUT = ""
$HAS_A_FLAG = $false
$HAS_R_FLAG = $false

##
# 오류 발생 시 도움말 메시지를 출력합니다.
#
# @param $1 {string} 에러 원인 (Cause)
#
# @returns 도움말 출력
##
function Show-Help ([string]$Cause = "") {
    if (-not [string]::IsNullOrEmpty($Cause)) {
        Write-Host "`n================================================================================"
        Write-Host (" - {0,-10}: {1}" -f "filename", $FILENAME)
        Write-Host (" - {0,-10}: {1}" -f "cause", $Cause)
        Write-Host "================================================================================"
    }
    Write-Host "`nUsage: .\$FILENAME [OPTIONS]"
    Write-Host "Options:"
    Write-Host "  -h, --help                  도움말 메시지를 출력합니다."
    Write-Host "  -d, --dry-run               실제 시스템에 반영하지 않고 예정된 구성 설정을 화면에 출력합니다."
    Write-Host "  -a, --add-vlan-networks     추가할 대상 VLAN 대역 (CIDR, 콤마 구분)"
    Write-Host "  -r, --remove-vlan-networks  제거할 대상 VLAN 대역 (CIDR, 콤마 구분)`n"
    Write-Host "설명:"
    Write-Host "  본 스크립트는 서버가 속한 물리 인터페이스를 자동 식별하고,"
    Write-Host "  목적지 VLAN 대역으로 향하는 영구(Permanent) 정적 라우팅을 제어합니다."
}

# 1. 파라미터 옵션 처리 파이프라인
$i = 0
while ($i -lt $ScriptArgs.Length) {
    $arg = $ScriptArgs[$i]
    switch -Regex ($arg) {
        '^(-h|--help)$' {
            Show-Help
            exit 0
        }
        '^(-d|--dry-run)$' {
            $DRY_RUN = $true
            $i++
        }
        '^(-a|--add-vlan-networks)$' {
            $HAS_A_FLAG = $true
            if (($i + 1) -lt $ScriptArgs.Length -and $ScriptArgs[$i+1] -notmatch '^-') {
                $ADD_VLAN_INPUT = $ScriptArgs[$i+1]
                $i += 2
            } else {
                $i++
            }
        }
        '^(-r|--remove-vlan-networks)$' {
            $HAS_R_FLAG = $true
            if (($i + 1) -lt $ScriptArgs.Length -and $ScriptArgs[$i+1] -notmatch '^-') {
                $REMOVE_VLAN_INPUT = $ScriptArgs[$i+1]
                $i += 2
            } else {
                $i++
            }
        }
        default {
            Show-Help "알 수 없는 옵션입니다: $arg"
            exit 1
        }
    }
}

##
# CIDR을 기반으로 정확한 서브넷을 추출하는 연산기 (오버플로우 방지 적용)
#
# @param $IpAndCidr {string} IP/CIDR (예: 10.11.1.14/16)
#
# @returns {string} 네트워크 주소 (예: 10.11.0.0/16)
##
function Get-NetworkAddress ($IpAndCidr) {
    $ip, $cidrStr = $IpAndCidr.Split('/')
    $cidr = [int]$cidrStr
    $ipBytes = [System.Net.IPAddress]::Parse($ip).GetAddressBytes()
    if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($ipBytes) }

    $ipNum = [BitConverter]::ToUInt32($ipBytes, 0)
    
    $maskBinStr = ('1' * $cidr) + ('0' * (32 - $cidr))
    $maskNum = [Convert]::ToUInt32($maskBinStr, 2)
    
    $netNum = $ipNum -band $maskNum

    $netBytes = [BitConverter]::GetBytes($netNum)
    if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($netBytes) }
    $netIp = [System.Net.IPAddress]::new($netBytes)
    return "$($netIp.IPAddressToString)/$cidr"
}

##
# 서브넷 마스크(Subnet Mask) 변환기 (CIDR -> 255.255.x.x)
#
# @param $Cidr {int} CIDR Prefix 길이
#
# @returns {string} 변환된 서브넷 마스크 문자열
##
function Get-SubnetMaskString ($Cidr) {
    $maskBinStr = ('1' * $Cidr) + ('0' * (32 - $Cidr))
    $maskNum = [Convert]::ToUInt32($maskBinStr, 2)
    
    $bytes = [BitConverter]::GetBytes($maskNum)
    if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($bytes) }
    return ([System.Net.IPAddress]::new($bytes)).IPAddressToString
}

##
# Windows 커널 라우팅 기반 자가 진단
#
# @returns {hashtable} 인터페이스 및 대역 정보 해시테이블 반환
##
function Find-VlanInterface {
    $defRoute = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1
    if (-not $defRoute) { return $null }

    $defGw = $defRoute.NextHop
    $ifaceIndex = $defRoute.InterfaceIndex
    $ifaceAlias = (Get-NetAdapter -InterfaceIndex $ifaceIndex).Name

    # Trunk GW 자동 계산 (끝자리 +1)
    $gwParts = $defGw.Split('.')
    $gwParts[3] = [string]([int]$gwParts[3] + 1)
    $trunkGw = $gwParts -join '.'

    # 인터페이스 IP 획득
    $ipInfo = Get-NetIPAddress -InterfaceIndex $ifaceIndex -AddressFamily IPv4 | Sort-Object PrefixOrigin -Descending | Select-Object -First 1
    if (-not $ipInfo) { return $null }

    $curSubnet = Get-NetworkAddress "$($ipInfo.IPAddress)/$($ipInfo.PrefixLength)"

    return @{
        IfaceAlias = $ifaceAlias
        IfaceIndex = $ifaceIndex
        Subnet = $curSubnet
        DefGw = $defGw
        TrunkGw = $trunkGw
    }
}

##
# 콤마(,) 구분자를 파싱하고 공백을 Trim 처리하여 배열로 반환합니다.
#
# @param $inputStr {string} 원본 입력 문자열
#
# @returns {array} 정제된 네트워크 배열
##
function Parse-Networks ($inputStr) {
    if ([string]::IsNullOrWhiteSpace($inputStr)) { return @() }
    return ($inputStr -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
}

##
# 현재 설정된 시스템 정적 라우팅 상태를 화면에 정렬하여 출력합니다.
#
# @param $IfaceAlias {string} 대상 물리 인터페이스명
# @param $CurSubnet {string} 서버의 소속 네트워크 대역
# @param $IfaceIndex {int} 인터페이스 인덱스
#
# @returns 시스템 상태 출력
##
function Show-CurrentRoutes ($IfaceAlias, $CurSubnet, $IfaceIndex) {
    Write-Host "`n================================================================================"
    Write-Host "💡 [정보] 현재 설정된 시스템 정적 라우팅 상태 (인터페이스: $IfaceAlias)"
    Write-Host "   - 서버 소속 네트워크(Netmask) : $CurSubnet"
    Write-Host "--------------------------------------------------------------------------------"
    
    $routes = Get-NetRoute -InterfaceIndex $IfaceIndex -AddressFamily IPv4 | Where-Object { $_.DestinationPrefix -ne '0.0.0.0/0' -and $_.NextHop -ne '0.0.0.0' }
    
    if (-not $routes) {
        Write-Host "   > 추가된 정적 라우팅 없음"
    } else {
        foreach ($r in $routes) {
            $dst = $r.DestinationPrefix.PadRight(18)
            $via = "via".PadRight(4)
            $nh = $r.NextHop.PadRight(15)
            $proto = "proto".PadRight(6)
            $static = "static".PadRight(7)
            $metricLabel = "metric".PadRight(7)
            $metric = $r.RouteMetric.ToString().PadRight(5)
            Write-Host "   > $dst $via $nh $proto $static $metricLabel $metric"
        }
    }
    Write-Host "================================================================================`n"
}

# --- 메인 비즈니스 로직 제어 런타임 ---

$VlanInfo = Find-VlanInterface
if (-not $VlanInfo) {
    Show-Help "시스템 라우팅 테이블에서 통신 가능한 물리 인터페이스와 서브넷을 식별하지 못했습니다."
    exit 1
}

$IFACE = $VlanInfo.IfaceAlias
$IFACE_IDX = $VlanInfo.IfaceIndex
$CUR_SUBNET = $VlanInfo.Subnet
$DEF_GW = $VlanInfo.DefGw
$TRUNK_GW = $VlanInfo.TrunkGw

# [단계 2] 프리플라이트 상태 점검 출력
Show-CurrentRoutes $IFACE $CUR_SUBNET $IFACE_IDX

# [단계 3] 넥스트 홉 대화형 입력
Write-Host "⚙️ [설정] 목적지 넥스트 홉(Gateway) IP 지정"
Write-Host "   스크립트가 자동 계산한 기본 Trunk Gateway IP는 [$TRUNK_GW] 입니다."
Write-Host "   다른 IP를 사용하려면 아래에 입력하시고, 기본값을 유지하려면 Enter 키를 누르세요."
$InputGW = Read-Host " ╰─▶ Next-hop Gateway IP [$TRUNK_GW]"
$InputGW = $InputGW.Trim()

if (-not [string]::IsNullOrEmpty($InputGW)) {
    if ($InputGW -match '^[0-9]{1,3}(\.[0-9]{1,3}){3}$') {
        $TRUNK_GW = $InputGW
    } else {
        Show-Help "입력한 Gateway IP($InputGW) 형식이 올바른 IPv4 주소가 아닙니다."
        exit 1
    }
}
Write-Host ""

# [단계 4] 옵션 파이프라인 무결성 확보 규칙 처리
if ($HAS_A_FLAG -and [string]::IsNullOrEmpty($ADD_VLAN_INPUT) -and $HAS_R_FLAG -and [string]::IsNullOrEmpty($REMOVE_VLAN_INPUT)) {
    Show-Help "-a 옵션과 -r 옵션을 인자 없이 동시에 사용할 수 없습니다."
    exit 1
}

if (-not $HAS_A_FLAG -and -not $HAS_R_FLAG -and [string]::IsNullOrEmpty($ADD_VLAN_INPUT) -and [string]::IsNullOrEmpty($REMOVE_VLAN_INPUT)) {
    $HAS_A_FLAG = $true
}

if ($HAS_A_FLAG -and [string]::IsNullOrEmpty($ADD_VLAN_INPUT) -and -not $HAS_R_FLAG -and [string]::IsNullOrEmpty($REMOVE_VLAN_INPUT)) {
    Write-Host "⚙️ [설정] 네트워크 추가/삭제 대역 지정 (자신이 속한 대역 제외)"
    Write-Host "   - CIDR Notation, 여러 개인 경우 콤마(,)로 구분"
    Write-Host "   - 예시: 10.11.0.0/16,10.12.0.0/16"
    $ADD_VLAN_INPUT = Read-Host " ├─▶ Add VLAN Networks (추가할 대역, 없으면 Enter)"
    $REMOVE_VLAN_INPUT = Read-Host " ╰─▶ Remove VLAN Networks (삭제할 대역, 없으면 Enter)"
    Write-Host ""
} else {
    if ($HAS_A_FLAG -and [string]::IsNullOrEmpty($ADD_VLAN_INPUT)) {
        Write-Host "⚙️ [설정] 네트워크 추가 대역 지정 (자신이 속한 대역 제외)"
        $ADD_VLAN_INPUT = Read-Host " ╰─▶ Add VLAN Networks (CIDR, 콤마 구분)"
        Write-Host ""
    }
    if ($HAS_R_FLAG -and [string]::IsNullOrEmpty($REMOVE_VLAN_INPUT)) {
        Write-Host "⚙️ [설정] 네트워크 삭제 대역 지정 (자신이 속한 대역 제외)"
        $REMOVE_VLAN_INPUT = Read-Host " ╰─▶ Remove VLAN Networks (CIDR, 콤마 구분)"
        Write-Host ""
    }
}

if ([string]::IsNullOrWhiteSpace($ADD_VLAN_INPUT + $REMOVE_VLAN_INPUT)) {
    Show-Help "추가 또는 삭제할 VLAN 네트워크가 지정되지 않았습니다. 작업을 취소합니다."
    exit 1
}

$ADD_NETWORKS = Parse-Networks $ADD_VLAN_INPUT
$REMOVE_NETWORKS = Parse-Networks $REMOVE_VLAN_INPUT

Write-Host "🚀 [실행] 네트워크 라우팅 변경 작업 시작"
$ModeStr = if ($DRY_RUN) { " 🧪 DRY-RUN (시뮬레이션 모드)" } else { " ⚡ RUN (실제 시스템 반영 모드)" }
Write-Host "   - 가동 모드            :$ModeStr"
Write-Host "   - 감지된 OS 유형       : Windows 11"
Write-Host "   - 할당 물리 인터페이스 : $IFACE"
Write-Host "   - 서버 자동 식별 대역  : $CUR_SUBNET"
Write-Host "   - 목적지 넥스트 홉(GW) : $TRUNK_GW"
Write-Host "--------------------------------------------------------------------------------"

# [단계 5] 삭제(Remove) 파이프라인
if ($REMOVE_NETWORKS.Count -gt 0) {
    Write-Host " 🗑️ [1단계] 라우팅 제거 작업 진행"
    foreach ($subnet in $REMOVE_NETWORKS) {
        if ($subnet -ne $CUR_SUBNET) {
            $targetIp, $targetCidr = $subnet.Split('/')
            if ($DRY_RUN) {
                Write-Host "   🧪 [DRY-RUN] 삭제: route delete $targetIp"
            } else {
                $null = route delete $targetIp 2>$null
                Write-Host "   ✅ [삭제 완료] $subnet"
            }
        } else {
            Write-Host "   ⏭️ [건너뜀] 현재 서버의 소속 대역과 동일한 입력 정보는 작업 대상에서 제외됩니다: $subnet"
        }
    }
    Write-Host ""
}

# [단계 6] 추가(Add) 파이프라인
if ($ADD_NETWORKS.Count -gt 0) {
    Write-Host " ➕ [2단계] 라우팅 추가 작업 진행"
    foreach ($subnet in $ADD_NETWORKS) {
        if ($subnet -ne $CUR_SUBNET) {
            $targetIp, $targetCidr = $subnet.Split('/')
            $maskStr = Get-SubnetMaskString -Cidr ([int]$targetCidr)
            
            if ($DRY_RUN) {
                Write-Host "   🧪 [DRY-RUN] 추가: route -p add $targetIp mask $maskStr $TRUNK_GW IF $IFACE_IDX"
            } else {
                $null = route -p add $targetIp mask $maskStr $TRUNK_GW IF $IFACE_IDX
                Write-Host "   ✅ [추가 완료] $subnet"
            }
        } else {
            Write-Host "   ⏭️ [건너뜀] 현재 서버의 소속 대역과 동일한 입력 정보는 작업 대상에서 제외됩니다: $subnet"
        }
    }
    Write-Host ""
}

Write-Host "================================================================================"
Write-Host "🎉 모든 라이프사이클 작업이 안전하게 완료되었습니다."
exit 0
