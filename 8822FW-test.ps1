function Test-Ping {
    param([string]$IP)
    try {
        $ping = New-Object System.Net.NetworkInformation.Ping
        $reply = $ping.Send($IP, 1000)
        if ($reply.Status -eq "Success") { return $reply.RoundtripTime } else { return "-" }
    } catch { return "-" }
}

function Test-Port {
    param(
        [string]$IP,
        [int[]]$Ports
    )

    $openPorts = @()
    foreach ($port in $Ports) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.Connect($IP, $port)
            $tcp.Close()
            $openPorts += $port
        } catch {}
    }
    if ($openPorts.Count -eq 0) { return "-" }
    else { return ($openPorts -join ",") }
}

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
$Results = @{}
foreach ($ip in $IPList) { $Results[$ip] = $null }

while ($true) {
    Check-AllIPs -IPList $IPList -PortList $PortList -Results $Results
    Update-Table -Results $Results
    Start-Sleep -Seconds 5
}