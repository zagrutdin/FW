# Автор: Флорит Загрутдинов
# Телефон: +7 917 272-22-88

$PortList = @(22,80,443)


$IPList = @"
10.148.196.131
10.148.196.132
10.148.196.133
10.148.196.134
10.148.196.135
10.148.196.201
10.148.196.202
10.148.196.140
10.148.196.141
10.148.196.142
10.148.196.217
10.148.196.145
10.148.196.144
10.148.196.146
10.148.195.131
10.148.195.132
10.148.195.133
10.148.195.201
10.148.195.202
10.148.195.141
10.148.195.142
"@ -split "`n"





































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



$Results = @{}
foreach ($ip in $IPList) { $Results[$ip] = $null }

while ($true) {
    Check-AllIPs -IPList $IPList -PortList $PortList -Results $Results
    Update-Table -Results $Results
    Start-Sleep -Seconds 5
}



WARNING: Name resolution of 10.148.196.145 failed
WARNING: Name resolution of 10.148.196.144 failed
WARNING: Name resolution of 10.148.196.144 failed
WARNING: Name resolution of 10.148.196.144 failed
WARNING: Name resolution of 10.148.196.146 failed
WARNING: Name resolution of 10.148.196.146 failed
WARNING: Name resolution of 10.148.196.146 failed
WARNING: Name resolution of 10.148.195.131 failed
WARNING: Name resolution of 10.148.195.131 failed
WARNING: Name resolution of 10.148.195.131 failed
WARNING: Name resolution of 10.148.195.132 failed
WARNING: Name resolution of 10.148.195.132 failed
WARNING: Name resolution of 10.148.195.132 failed
WARNING: Name resolution of 10.148.195.133 failed
WARNING: Name resolution of 10.148.195.133 failed
WARNING: Name resolution of 10.148.195.133 failed
WARNING: Name resolution of 10.148.195.201 failed
WARNING: Name resolution of 10.148.195.201 failed
WARNING: Name resolution of 10.148.195.201 failed
WARNING: Name resolution of 10.148.195.202 failed
WARNING: Name resolution of 10.148.195.202 failed
WARNING: Name resolution of 10.148.195.202 failed
WARNING: Name resolution of 10.148.195.141 failed
WARNING: Name resolution of 10.148.195.141 failed
WARNING: Name resolution of 10.148.195.141 failed
WARNING: TCP connect to (10.148.195.142 : 22) failed
