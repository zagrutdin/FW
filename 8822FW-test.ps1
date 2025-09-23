# ==================== Функции ====================

# Метод ping
function Test-Ping {
    param([string]$IP)
    try {
        $reply = Test-Connection -ComputerName $IP -Count 1 -ErrorAction Stop | Select-Object -First 1
        if ($reply) { return $reply.ResponseTime } else { return "-" }
    } catch { return "-" }
}

# Метод проверки TCP-порта
function Test-Port {
    param(
        [string]$IP,
        [int[]]$Ports
    )

    $openPorts = @()
    foreach ($port in $Ports) {
        try {
            $result = Test-NetConnection -ComputerName $IP -Port $port -InformationLevel Quiet
            if ($result) { $openPorts += $port }
        } catch {}
    }
    if ($openPorts.Count -eq 0) { return "-" }
    else { return ($openPorts -join ",") }
}

# Проверка всех IP и сбор данных
function Check-AllIPs {
    param(
        [string[]]$IPList,
        [int[]]$PortList,
        [hashtable]$Results
    )

    foreach ($ip in $IPList) {
        $Results[$ip] = [PSCustomObject]@{
            "Ping (мс)" = Test-Ping -IP $ip
            "Открытые порты" = Test-Port -IP $ip -Ports $PortList
        }
    }
}

# Вывод таблицы
function Update-Table {
    param([hashtable]$Results)
    Clear-Host
    Write-Host "Мониторинг устройств — $(Get-Date)" -ForegroundColor Cyan
    Write-Host "----------------------------------------------------------`n"

    $Results.GetEnumerator() |
        Sort-Object Name |
        ForEach-Object {
            $ip = $_.Name.PadRight(15)
            $ping = $_.Value."Ping (мс)".ToString().PadRight(8)
            $ports = $_.Value."Открытые порты"
            Write-Host "$ip`t$ping`t$ports"
        }
}

# ==================== Основное выполнение ====================

# Список IP и портов задается заранее
# Пример:
# $IPList = @("10.0.0.1","10.0.0.2")
# $PortList = @(22,80,443)

$Results = @{}
foreach ($ip in $IPList) { $Results[$ip] = $null }

while ($true) {
    Check-AllIPs -IPList $IPList -PortList $PortList -Results $Results
    Update-Table -Results $Results
    Start-Sleep -Seconds 5
}