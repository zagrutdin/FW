# Порты
$PortList = @(22, 80, 443)

# Инициализация результатов
$Results = @{}
foreach ($ip in $IPList) {
    $Results[$ip] = [PSCustomObject]@{
        "Ping" = "NotSent"
        "PingTime(ms)" = "-"
        "OpenPorts" = "-"
        "Status" = "NotChecked"
    }
}

# Проверка одного IP
function Check-IP {
    param(
        [string]$IP,
        [int[]]$PortList,
        [hashtable]$Results
    )

    # Ping
    try {
        $pingObj = New-Object System.Net.NetworkInformation.Ping
        $reply = $pingObj.Send($IP, 1000)
        if ($reply.Status -eq "Success") {
            $Results[$IP].Ping = "ResponseReceived"
            $Results[$IP]."PingTime(ms)" = $reply.RoundtripTime
        } else {
            $Results[$IP].Ping = "NoResponse"
            $Results[$IP]."PingTime(ms)" = "-"
        }
    } catch {
        $Results[$IP].Ping = "Error"
        $Results[$IP]."PingTime(ms)" = "-"
    }

    # Порты
    $openPorts = @()
    foreach ($port in $PortList) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.Connect($IP, $port)
            $tcp.Close()
            $openPorts += $port
        } catch {}
    }
    if ($openPorts.Count -eq 0) { $Results[$IP].OpenPorts = "NoOpenPort" }
    else { $Results[$IP].OpenPorts = ($openPorts -join ",") }

    # Статус
    if ($Results[$IP].Ping -eq "ResponseReceived" -and $Results[$IP].OpenPorts -ne "NoOpenPort") {
        $Results[$IP].Status = "OK"
    } elseif ($Results[$IP].Ping -ne "ResponseReceived") {
        $Results[$IP].Status = "NoPing"
    } elseif ($Results[$IP].OpenPorts -eq "NoOpenPort") {
        $Results[$IP].Status = "NoOpenPort"
    } else {
        $Results[$IP].Status = "Unknown"
    }
}

# Вывод таблицы
function Update-Table {
    param([hashtable]$Results)
    Clear-Host
    Write-Host "Мониторинг устройств — $(Get-Date)" -ForegroundColor Cyan
    Write-Host "-------------------------------------------------------------`n"

    $Results.GetEnumerator() |
        Sort-Object Name |
        ForEach-Object {
            $ip = $_.Name.PadRight(15)
            $ping = $_.Value.Ping.PadRight(15)
            $pingTime = $_.Value."PingTime(ms)".ToString().PadRight(8)
            $ports = $_.Value.OpenPorts.PadRight(15)
            $status = $_.Value.Status
            Write-Host "$ip`t$ping`t$pingTime`t$ports`t$status"
        }
}

# Основной цикл
while ($true) {
    foreach ($ip in $IPList) {
        Check-IP -IP $ip -PortList $PortList -Results $Results
    }
    Update-Table -Results $Results
    Start-Sleep -Seconds 2
}