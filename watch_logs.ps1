$logFile = "flutter_output.txt"
$lastSize = 0

Write-Host "Monitoreando logs de Flutter..."
Write-Host "Presiona Ctrl+C para detener"
Write-Host ""

while ($true) {
    if (Test-Path $logFile) {
        $currentSize = (Get-Item $logFile).Length
        if ($currentSize -gt $lastSize) {
            $newContent = Get-Content $logFile -Tail 20
            $newContent | ForEach-Object { Write-Host $_ }
            $lastSize = $currentSize
        }
    }
    Start-Sleep -Seconds 2
}

