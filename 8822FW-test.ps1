function Test-IP {
    param([string]$IP)

    try {
        # Используем Test-Connection с -Count 1 и выводим ResponseTime
        $ping = Test-Connection -ComputerName $IP -Count 1 -ErrorAction Stop | Select-Object -First 1
        if ($ping) {
            return $ping.ResponseTime
        } else {
            return "-"
        }
    }
    catch {
        return "-"
    }
}

function Update-Table {
    param([hashtable]$ResponseTimes)

    Clear-Host
    Write-Host "Мониторинг отклика устройств — $(Get-Date)" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------`n"

    $ResponseTimes.GetEnumerator() | 
        Sort-Object Name | 
        ForEach-Object {
            $ip = $_.Name.PadRight(15)
            $time = $_.Value.ToString().PadRight(8)
            Write-Host "$ip`t$time"
        }
}

function Check-AllIPs {
    param(
        [string[]]$IPList,
        [hashtable]$ResponseTimes
    )

    foreach ($ip in $IPList) {
        # обновляем хэш сразу по каждому IP
        $ResponseTimes[$ip] = Test-IP -IP $ip
    }
}

# ===== Основное выполнение =====
# Предполагается, что $IPList определён заранее
$ResponseTimes = @{}
foreach ($ip in $IPList) { $ResponseTimes[$ip] = "-" }

while ($true) {
    Check-AllIPs -IPList $IPList -ResponseTimes $ResponseTimes
    Update-Table -ResponseTimes $ResponseTimes
    Start-Sleep -Seconds 2
}