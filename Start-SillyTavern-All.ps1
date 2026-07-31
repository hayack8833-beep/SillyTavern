$ErrorActionPreference = 'Stop'

$SillyTavernRoot = 'C:\Users\hayack\Documents\eroAI\SillyTavern'
$RuntimeRoot = 'C:\Users\hayack\Documents\eroAI\ero_ai\.runtime'
$Ollama = 'C:\Users\hayack\Documents\eroAI\ero_ai\.tools\ollama\ollama.exe'
$OllamaModels = 'C:\Users\hayack\Documents\eroAI\ero_ai\.ollama_models'
$Node = 'C:\Users\hayack\Documents\eroAI\ero_ai\.tools\node-v22.23.1-win-x64\node.exe'
$Url = 'http://127.0.0.1:8000/'

function Test-ListeningPort {
    param([int]$Port)

    return $null -ne (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1)
}

function Wait-ListeningPort {
    param(
        [int]$Port,
        [int]$TimeoutSeconds
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-ListeningPort -Port $Port) {
            return $true
        }
        Start-Sleep -Seconds 1
    }
    return $false
}

foreach ($requiredPath in @($SillyTavernRoot, $RuntimeRoot, $Ollama, $OllamaModels, $Node)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Required path was not found: $requiredPath"
    }
}

if (-not (Test-ListeningPort -Port 11434)) {
    Write-Host 'Starting Ollama...'
    $env:OLLAMA_MODELS = $OllamaModels
    $ollamaProcess = Start-Process `
        -FilePath $Ollama `
        -ArgumentList 'serve' `
        -WorkingDirectory (Split-Path -Parent $Ollama) `
        -WindowStyle Minimized `
        -PassThru
    $ollamaProcess.Id | Set-Content -LiteralPath (Join-Path $RuntimeRoot 'ollama.pid') -Encoding ASCII

    if (-not (Wait-ListeningPort -Port 11434 -TimeoutSeconds 30)) {
        throw 'Ollama did not start on http://127.0.0.1:11434 within 30 seconds.'
    }
} else {
    Write-Host 'Ollama is already running.'
}

if (-not (Test-ListeningPort -Port 8000)) {
    Write-Host 'Starting SillyTavern...'
    $sillyTavernProcess = Start-Process `
        -FilePath $Node `
        -ArgumentList 'server.js' `
        -WorkingDirectory $SillyTavernRoot `
        -WindowStyle Minimized `
        -PassThru
    $sillyTavernProcess.Id | Set-Content -LiteralPath (Join-Path $RuntimeRoot 'sillytavern.pid') -Encoding ASCII

    if (-not (Wait-ListeningPort -Port 8000 -TimeoutSeconds 60)) {
        throw 'SillyTavern did not start on http://127.0.0.1:8000 within 60 seconds.'
    }
} else {
    Write-Host 'SillyTavern is already running.'
}

$statusCode = (Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 10).StatusCode
if ($statusCode -ne 200) {
    throw "SillyTavern returned HTTP status $statusCode."
}

Write-Host "Ready: $Url"
Start-Process $Url
