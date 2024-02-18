function WaitForInput {
    $timeout = 15
    $startTime = Get-Date

    while ($true) {
        $elapsedTime = (Get-Date) - $startTime

        if ($elapsedTime.TotalSeconds -ge $timeout) {
            # If 15 seconds have passed, assume 'y'
            return 'y'
        }

        if ([System.Console]::KeyAvailable) {
            $key = [System.Console]::ReadKey($true).Key

            if ($key -eq 'Y') {
                return 'y'
            } elseif ($key -eq 'N') {
                return 'n'
            }
        }

        Start-Sleep -Milliseconds 100
    }
}

function Update-UrlWithParameter {
    param (
        [string]$url,
        [string]$parameterName,
        [string]$parameterValue
    )

    # Parse the URL to separate the base URL and existing parameters
    $baseUri = [System.Uri]$url
    $query = [System.Web.HttpUtility]::ParseQueryString($baseUri.Query)

    # Check if the parameter already exists, and update or append accordingly
    if ($query.Get($parameterName) -ne $null) {
        $query.Set($parameterName, $parameterValue)
    } else {
        $query.Add($parameterName, $parameterValue)
    }

    # Rebuild the URL with the updated parameters
    $updatedUrl = $baseUri.GetLeftPart([System.UriPartial]::Path) + '?' + $query.ToString()

    return $updatedUrl
}

Write-Host "Are you sure you want to install? Installing in 15 seconds... (y/n)"
$shouldInstall = WaitForInput

if ($shouldInstall -eq 'n') {
    Write-Host "Installation cancelled."
    Read-Host
    exit
}

Write-Host "Checking directory..."
if (-not (Test-Path "echovr.exe")) {
    Write-Host "echovr.exe not found."
    Read-Host
    exit
}

Write-Host "Stopping game..."
Stop-Process -Name "echovr"
while (Get-Process -Name "echovr" -ErrorAction SilentlyContinue) {
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
