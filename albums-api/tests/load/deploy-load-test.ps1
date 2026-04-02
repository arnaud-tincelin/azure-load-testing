<#
.SYNOPSIS
    Deploys the JMeter load test to Azure Load Testing.

.DESCRIPTION
    Creates or updates a load test in Azure Load Testing using the JMeter test plan
    and configuration from this directory.

.PARAMETER ResourceGroup
    The Azure resource group containing the Load Testing resource.

.PARAMETER LoadTestingResourceName
    The name of the Azure Load Testing resource.

.PARAMETER TargetHost
    The hostname of the Albums API (without protocol or trailing slash).

.PARAMETER Protocol
    The protocol to use (default: https).

.PARAMETER Port
    The port to use (default: 443).
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$LoadTestingResourceName,

    [Parameter(Mandatory = $true)]
    [string]$TargetHost,

    [string]$Protocol = "https",

    [string]$Port = "443"
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$testId = "albums-api-load-test"
$testPlanFile = Join-Path $scriptDir "album-api-load-test.jmx"
$configFile = Join-Path $scriptDir "load-test.yaml"

Write-Host "Deploying load test to Azure Load Testing..." -ForegroundColor Cyan
Write-Host "  Resource Group : $ResourceGroup"
Write-Host "  ALT Resource   : $LoadTestingResourceName"
Write-Host "  Target Host    : $TargetHost"
Write-Host "  Protocol       : $Protocol"
Write-Host "  Port           : $Port"

# Ensure the az load extension is installed
Write-Host "`nChecking Azure CLI load extension..." -ForegroundColor Yellow
az extension add --name load --only-show-errors 2>$null

# Update config file with actual target host
$configContent = Get-Content $configFile -Raw
$configContent = $configContent -replace '\$\{SERVICE_ALBUMS_API_ENDPOINT_URL\}', $TargetHost
$tempConfig = Join-Path ([System.IO.Path]::GetTempPath()) "load-test-config.yaml"
$configContent | Set-Content $tempConfig -NoNewline

# Create or update the load test using the config file
Write-Host "`nCreating load test '$testId'..." -ForegroundColor Yellow
az load test create `
    --test-id $testId `
    --load-test-resource $LoadTestingResourceName `
    --resource-group $ResourceGroup `
    --load-test-config-file $tempConfig `
    --env HOST=$TargetHost PORT=$Port PROTOCOL=$Protocol

Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue

Write-Host "`nLoad test '$testId' deployed successfully!" -ForegroundColor Green
Write-Host "You can now run it with: ./run-load-test.ps1 -ResourceGroup $ResourceGroup -LoadTestingResourceName $LoadTestingResourceName"
