# Список портов
$PortList = @(22, 80, 443)

# Хэш для хранения результатов
$Results = @{}
foreach ($ip in $IPList) { 
    $Results[$ip] = [PSCustomObject]@{
        "Ping (мс)" = "-"
        "Открытые порты" = "-"
    }
}

# Функция для проверки одного IP
function Check-IP {
    param(
        [string]$IP,
        [int[]]$PortList,
        [hashtable]$Results
    )

    # Ping через .NET
    try {
        $ping = New-Object System.Net.NetworkInformation.Ping
        $reply = $ping.Send($IP, 1000)
        if ($reply.Status -eq "Success") { $Results[$IP]."Ping (мс)" = $reply.RoundtripTime }
        else { $Results[$IP]."Ping (мс)" = "-" }
    } catch { $Results[$IP]."Ping (мс)" = "-" }

    # Проверка портов через TcpClient
    $openPorts = @()
    foreach ($port in $PortList) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.Connect($IP, $port)
            $tcp.Close()
            $openPorts += $port
        } catch {}
    }
    if ($openPorts.Count -eq 0) { $Results[$IP]."Открытые порты" = "-" }
    else { $Results[$IP]."Открытые порты" = ($openPorts -join ",") }
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
            $ping = $_.Value."Ping (мс)".ToString().PadRight(8)
            $ports = $_.Value."Открытые порты"
            Write-Host "$ip`t$ping`t$ports"
        }
}

# Основной цикл с параллельными джобами
while ($true) {
    $jobs = @()
    foreach ($ip in $IPList) {
        $jobs += Start-Job -ScriptBlock {
            param($ip, $PortList, $Results)
            Check-IP -IP $ip -PortList $PortList -Results $Results
        } -ArgumentList $ip, $PortList, $Results
    }

    # Обновление таблицы каждые 2 секунды, пока идут джобы
    do {
        Update-Table -Results $Results
        Start-Sleep -Seconds 2
        $running = $jobs | Where-Object { $_.State -eq 'Running' }
    } while ($running.Count -gt 0)

    # Получение оставшихся результатов и удаление джобов
    foreach ($job in $jobs) {
        Receive-Job -Job $job -Keep | Out-Null
        Remove-Job -Job $job
    }

    Start-Sleep -Seconds 2
}