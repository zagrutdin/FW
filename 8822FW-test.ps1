# Список портов
$PortList = @(22, 80, 443)

# Инициализация хэша результатов
$Results = @{}
foreach ($ip in $IPList) { 
    $Results[$ip] = [PSCustomObject]@{
        "Ping (мс)" = 0
        "Открытые порты" = 0
        "Status" = 0       # начальный статус
    }
}

# Функция проверки одного IP
function Check-IP {
    param(
        [string]$IP,
        [int[]]$PortList,
        [hashtable]$Results
    )

    # Проверка ping
    try {
        $ping = New-Object System.Net.NetworkInformation.Ping
        $reply = $ping.Send($IP, 1000)
        if ($reply.Status -eq "Success") { 
            $Results[$IP]."Ping (мс)" = $reply.RoundtripTime
            $pingStatus = "PingOK"
        } else { 
            $Results[$IP]."Ping (мс)" = "NoPing"
            $pingStatus = "NoPing"
        }
    } catch { 
        $Results[$IP]."Ping (мс)" = "NoPing"
        $pingStatus = "NoPing"
    }

    # Проверка TCP-портов
    $openPorts = @()
    foreach ($port in $PortList) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.Connect($IP, $port)
            $tcp.Close()
            $openPorts += $port
        } catch {}
    }
    if ($openPorts.Count -eq 0) { 
        $Results[$IP]."Открытые порты" = "NoOpenPort"
        $portStatus = "NoOpenPort"
    } else { 
        $Results[$IP]."Открытые порты" = ($openPorts -join ",")
        $portStatus = "PortsOK"
    }

    # Обновление общего статуса по логике: если ping не прошёл → NoPing, если порты закрыты → NoOpenPort, иначе OK
    if ($pingStatus -eq "NoPing") { $Results[$IP].Status = "NoPing" }
    elseif ($portStatus -eq "NoOpenPort") { $Results[$IP].Status = "NoOpenPort" }
    else { $Results[$IP].Status = "OK" }
}

# Функция вывода таблицы
function Update-Table {
    param([hashtable]$Results)
    Clear-Host
    Write-Host "Мониторинг устройств — $(Get-Date)" -ForegroundColor Cyan
    Write-Host "----------------------------------------------------------`n"

    $Results.GetEnumerator() |
        Sort-Object Name |
        ForEach-Object {
            $ip = $_.Name.PadRight(15)
            $ping = $_.Value."Ping (мс)".ToString().PadRight(10)
            $ports = $_.Value."Открытые порты".ToString().PadRight(15)
            $status = $_.Value.Status
            Write-Host "$ip`t$ping`t$ports`t$status"
        }
}

# Основной цикл
while ($true) {
    $jobs = @()
    foreach ($ip in $IPList) {
        $jobs += Start-Job -ScriptBlock {
            param($ip, $PortList, $Results)
            Check-IP -IP $ip -PortList $PortList -Results $Results
        } -ArgumentList $ip, $PortList, $Results
    }

    # Таблица обновляется каждые 2 секунды пока идут джобы
    do {
        Update-Table -Results $Results
        Start-Sleep -Seconds 2
        $running = $jobs | Where-Object { $_.State -eq 'Running' }
    } while ($running.Count -gt 0)

    foreach ($job in $jobs) {
        Receive-Job -Job $job -Keep | Out-Null
        Remove-Job -Job $job
    }

    Start-Sleep -Seconds 2
}