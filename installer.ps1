function Update-UrlWithParameter {
    param (
        [string]$url,
        [string]$parameterName,
        [string]$parameterValue
    )

    $baseUri = [System.Uri]$url
    $query = [System.Web.HttpUtility]::ParseQueryString($baseUri.Query)

    if ($null -ne $query.Get($parameterName)) {
        $query.Set($parameterName, $parameterValue)
    } else {
        $query.Add($parameterName, $parameterValue)
    }
    
    $updatedUrl = "ws://$($baseUri.Host):$($baseUri.Port)$($baseUri.AbsolutePath)?$($query.ToString())"
    return $updatedUrl
}

Write-Host "Are you sure you want to install? (y/n)"
$confirmation = Read-Host
if ($confirmation -ne "y") {
    Write-Host "Installation cancelled."
    Read-Host "Press enter to exit"
    exit
}

Write-Host "Checking directory..."
if (-not (Test-Path "echovr.exe")) {
    Write-Host "echovr.exe not found."
    Read-Host
    exit
}

Write-Host "Stopping game..."
while (Get-Process -Name "echovr" -ErrorAction SilentlyContinue) {
    Stop-Process -Name "echovr"
    Start-Sleep -Seconds 1
}

Write-Host "Checking for conflicts..."
if (Test-Path "dbgcore.dll") {
    Write-Host "Found existing dbgcore.dll. Deleting..."
    Remove-Item -Force "dbgcore.dll"
}

Write-Host "Creating plugins folder..."
if (-not (Test-Path "plugins")) {
    New-Item -ItemType Directory -Path "plugins"
}

Write-Host "Downloading EchoLoader..."
$echoLoaderUrl = "https://github.com/EchoTools/EchoLoader/releases/latest/download/EchoLoader.dll"
Invoke-WebRequest -Uri $echoLoaderUrl -OutFile "dbgcore.dll"

Write-Host "Downloading SymbolPatch..."
$symbolPatchUrl = "https://github.com/EchoTools/SymbolPatch/releases/latest/download/SymbolPatch.dll"
Invoke-WebRequest -Uri $symbolPatchUrl -OutFile "plugins/SymbolPatch.dll"

Write-Host "Checking config..."
$configPath = "../../_local/config.json"
if (-not (Test-Path $configPath)) {
    Write-Host "config.json not found."
    Read-Host
    exit
}

Write-Host "Modifying config..."
$config = Get-Content $configPath | ConvertFrom-Json
$config.configservice_host = Update-UrlWithParameter -url $config.configservice_host -parameterName "platform" -parameterValue "rift-modded"
$config | ConvertTo-Json | Set-Content $configPath

Write-Host "Starting game..."
Start-Process "echovr.exe"

Write-Host "Installation complete."
Read-Host "Press enter to exit"
