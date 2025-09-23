# ==================== Функции ====================

# Метод 1: Test-Connection
function Ping-TestConnection {
    param([string]$IP)
    try {
        $reply = Test-Connection -ComputerName $IP -Count 1 -ErrorAction Stop | Select-Object -First 1
        if ($reply) { return $reply.ResponseTime } else { return "-" }
    } catch { return "-" }
}

# Метод 2: .NET Ping
function Ping-DotNet {
    param([string]$IP)
    try {
        $p = New-Object System.Net.NetworkInformation.Ping
        $reply = $p.Send($IP,1000)
        if ($reply.Status -eq "Success") { return $reply.RoundtripTime } else { return "-" }
    } catch { return "-" }
}

# Метод 3: Test-NetConnection TCP 80 (опционально)
function Ping-TCP {
    param([string]$IP)
    try {
        $res = Test-NetConnection -ComputerName $IP -Port 80 -InformationLevel Quiet
        if ($res) { return 1 } else { return "-" }
    } catch { return "-" }
}

# Функция проверки всех IP
function Check-AllIPs {
    param(
        [string[]]$IPList,
        [hashtable]$Results
    )

    foreach ($ip in $IPList) {
        $Results[$ip] = [PSCustomObject]@{
            "ICMP1" = Ping-TestConnection -IP $ip
            "ICMP2" = Ping-DotNet -IP $ip
            "TCP80" = Ping-TCP -IP $ip
        }
    }
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
            $icmp1 = $_.Value.ICMP1.ToString().PadRight(6)
            $icmp2 = $_.Value.ICMP2.ToString().PadRight(6)
            $tcp80 = $_.Value.TCP80.ToString().PadRight(4)
            Write-Host "$ip`t$icmp1`t$icmp2`t$tcp80"
        }
}

# ==================== Основное выполнение ====================

# $IPList предполагается определён вне скрипта
$Results = @{}
foreach ($ip in $IPList) { $Results[$ip] = $null }

while ($true) {
    Check-AllIPs -IPList $IPList -Results $Results
    Update-Table -Results $Results
    Start-Sleep -Seconds 2
}