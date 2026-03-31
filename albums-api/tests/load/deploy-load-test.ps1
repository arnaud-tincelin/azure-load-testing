<#
.SYNOPSIS
    Deploys the Albums API load test to Azure Load Testing.

.DESCRIPTION
    Creates or updates an Azure Load Testing test with the JMeter test plan
    and configuration. Requires the Azure CLI to be installed and logged in.

.PARAMETER ResourceGroup
    The Azure resource group containing the Azure Load Testing resource.

.PARAMETER LoadTestingResourceName
    The name of the Azure Load Testing resource.

.PARAMETER TargetHost
    The hostname of the Albums API endpoint (without protocol or port).

.PARAMETER TargetPort
    The port of the Albums API endpoint. Default is 443 for HTTPS.

.PARAMETER Protocol
    The protocol to use (http or https). Default is https.

.EXAMPLE
    ./deploy-load-test.ps1 `
        -ResourceGroup "rg-myenv" `
        -LoadTestingResourceName "lt-abc123" `
        -TargetHost "ca-albums-api-abc123.azurecontainerapps.io" `
        -Protocol "https"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$LoadTestingResourceName,

    [Parameter(Mandatory = $true)]
    [string]$TargetHost,

    [Parameter(Mandatory = $false)]
    [string]$TargetPort = "443",

    [Parameter(Mandatory = $false)]
    [string]$Protocol = "https"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$JmxFile = Join-Path $ScriptDir "album-api-load-test.jmx"
$LoadTestConfig = Join-Path $ScriptDir "load-test.yaml"

Write-Host "🚀 Deploying Albums API load test to Azure Load Testing..." -ForegroundColor Cyan
Write-Host "  Resource Group: $ResourceGroup"
Write-Host "  Load Testing Resource: $LoadTestingResourceName"
Write-Host "  Target: $Protocol`://$TargetHost`:$TargetPort"

# Verify Azure CLI is logged in
Write-Host "`n📋 Verifying Azure CLI login..." -ForegroundColor Yellow
$account = az account show --query "name" -o tsv 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Not logged in to Azure CLI. Run 'az login' first."
    exit 1
}
Write-Host "  Using subscription: $account" -ForegroundColor Green

# Get the Load Testing resource data plane endpoint
Write-Host "`n📋 Getting Azure Load Testing endpoint..." -ForegroundColor Yellow
$dataPlaneUri = az load show `
    --name $LoadTestingResourceName `
    --resource-group $ResourceGroup `
    --query "dataPlaneUri" `
    -o tsv

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to get Azure Load Testing resource. Ensure the resource exists."
    exit 1
}
Write-Host "  Data Plane URI: $dataPlaneUri" -ForegroundColor Green

# Create or update the load test
Write-Host "`n📤 Uploading test plan and configuration..." -ForegroundColor Yellow
az load test create `
    --load-test-resource $LoadTestingResourceName `
    --resource-group $ResourceGroup `
    --test-id "albums-api-load-test" `
    --display-name "Albums API Progressive Load Test" `
    --description "Progressive load test (0 to 1000 RPS) for Marketplace Albums API" `
    --test-plan $JmxFile `
    --env TARGET_HOST="$TargetHost" TARGET_PORT="$TargetPort" PROTOCOL="$Protocol" `
    --engine-instances 5

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to create/update load test."
    exit 1
}

Write-Host "`n✅ Load test deployed successfully!" -ForegroundColor Green
Write-Host "   Run 'run-load-test.ps1' to execute the test."
