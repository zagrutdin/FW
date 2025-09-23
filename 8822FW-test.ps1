# Автор: Флорит Загрутдинов
# Телефон: +7 917 272-22-88

# ==================== Функции ====================

# Функция пинга одного IP и возврата времени отклика
function Test-IP {
    param([string]$IP)

    try {
        $reply = Test-Connection -ComputerName $IP -Count 1 -ErrorAction Stop
        return $reply.ResponseTime
    }
    catch {
        return "-"
    }
}

# Функция обновления таблицы всех IP
function Update-Table {
    param([hashtable]$ResponseTimes)

    Clear-Host
    Write-Host "Мониторинг отклика устройств — $(Get-Date)" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------`n"

    $ResponseTimes.GetEnumerator() | 
        Sort-Object Name | 
        ForEach-Object {
            $ip = $_.Name.PadRight(15)    # ширина колонки для полного IP
            $time = $_.Value.ToString().PadRight(8)
            Write-Host "$ip`t$time"
        }
}

# Функция проверки всех IP и обновления хэш-таблицы
function Check-AllIPs {
    param(
        [string[]]$IPList,
        [hashtable]$ResponseTimes
    )

    foreach ($ip in $IPList) {
        $ResponseTimes[$ip] = Test-IP -IP $ip
    }
}

# ==================== Основное выполнение ====================

# Здесь предполагается, что $IPList определён заранее вне скрипта
# Пример: $IPList = @("10.148.196.131", "10.148.196.132", ...)

# Создание хэш-таблицы для хранения времени отклика
$ResponseTimes = @{}
foreach ($ip in $IPList) { $ResponseTimes[$ip] = "-" }

# Основной цикл мониторинга
while ($true) {
    Check-AllIPs -IPList $IPList -ResponseTimes $ResponseTimes
    Update-Table -ResponseTimes $ResponseTimes
    Start-Sleep -Seconds 2
}