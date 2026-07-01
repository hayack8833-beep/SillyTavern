$ErrorActionPreference = 'Stop'

$Runtime = 'C:\Users\hayack\Documents\eroAI\ero_ai\.runtime'
$Node = 'C:\Users\hayack\Documents\eroAI\ero_ai\.tools\node-v22.23.1-win-x64\node.exe'
$WorkingDirectory = 'C:\Users\hayack\Documents\eroAI\SillyTavern'
$OutLog = Join-Path $Runtime 'sillytavern.out.log'
$ErrLog = Join-Path $Runtime 'sillytavern.err.log'
$PidFile = Join-Path $Runtime 'sillytavern.pid'
$LauncherFile = Join-Path $Runtime 'run_sillytavern_server.ps1'
$CmdLauncher = Join-Path $WorkingDirectory 'Launch-SillyTavern.cmd'

New-Item -ItemType Directory -Force -Path $Runtime | Out-Null

$existingPid = $null
if (Test-Path -LiteralPath $PidFile) {
    $existingPid = Get-Content -LiteralPath $PidFile -ErrorAction SilentlyContinue | Select-Object -First 1
}

if ($existingPid) {
    $existing = Get-Process -Id $existingPid -ErrorAction SilentlyContinue
    if ($existing -and ($existing.ProcessName -eq 'node' -or $existing.ProcessName -eq 'powershell')) {
        Stop-Process -Id $existing.Id -Force
        Start-Sleep -Seconds 1
    }
}

$existingNodes = Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -eq 'node' -and $_.Path -eq $Node
}
foreach ($existingNode in $existingNodes) {
    Stop-Process -Id $existingNode.Id -Force
}

$process = Start-Process `
    -FilePath 'C:\Windows\System32\cmd.exe' `
    -ArgumentList @('/k', $CmdLauncher) `
    -WorkingDirectory $WorkingDirectory `
    -WindowStyle Normal `
    -PassThru

Start-Sleep -Seconds 15
$status = try {
    (Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:8000/' -TimeoutSec 5).StatusCode
} catch {
    $_.Exception.Message
}

$listener = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
if ($listener) {
    $listener.OwningProcess | Set-Content -LiteralPath $PidFile -Encoding ASCII
} else {
    $nodeProcess = Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -eq 'node' -and $_.Path -eq $Node
    } | Sort-Object StartTime -Descending | Select-Object -First 1
    if ($nodeProcess) {
        $nodeProcess.Id | Set-Content -LiteralPath $PidFile -Encoding ASCII
    }
}

Write-Output "PID: $(Get-Content -LiteralPath $PidFile)"
Write-Output "URL: http://127.0.0.1:8000/"
Write-Output "Status: $status"
