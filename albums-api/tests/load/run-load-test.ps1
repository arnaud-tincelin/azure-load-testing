<#
.SYNOPSIS
    Executes the Albums API load test on Azure Load Testing and retrieves results.

.DESCRIPTION
    Triggers the load test run, waits for completion, and downloads the results.
    Requires the Azure CLI to be installed and logged in.

.PARAMETER ResourceGroup
    The Azure resource group containing the Azure Load Testing resource.

.PARAMETER LoadTestingResourceName
    The name of the Azure Load Testing resource.

.PARAMETER OutputPath
    Directory where test results will be saved. Default is './results'.

.EXAMPLE
    ./run-load-test.ps1 `
        -ResourceGroup "rg-myenv" `
        -LoadTestingResourceName "lt-abc123"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$LoadTestingResourceName,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./results"
)

$ErrorActionPreference = "Stop"

Write-Host "🧪 Running Albums API load test..." -ForegroundColor Cyan
Write-Host "  Resource Group: $ResourceGroup"
Write-Host "  Load Testing Resource: $LoadTestingResourceName"

# Verify Azure CLI is logged in
Write-Host "`n📋 Verifying Azure CLI login..." -ForegroundColor Yellow
$account = az account show --query "name" -o tsv 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Not logged in to Azure CLI. Run 'az login' first."
    exit 1
}
Write-Host "  Using subscription: $account" -ForegroundColor Green

# Create the output directory
$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}
Write-Host "  Results directory: $OutputPath"

# Create a new test run
Write-Host "`n🚀 Creating test run..." -ForegroundColor Yellow
$testRunId = "run-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$startTime = Get-Date

az load test-run create `
    --load-test-resource $LoadTestingResourceName `
    --resource-group $ResourceGroup `
    --test-id "albums-api-load-test" `
    --test-run-id $testRunId `
    --display-name "Albums API Load Test - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to create test run."
    exit 1
}
Write-Host "  Test Run ID: $testRunId" -ForegroundColor Green

# Wait for test completion
Write-Host "`n⏳ Waiting for test to complete (this may take 15+ minutes)..." -ForegroundColor Yellow
$checkInterval = 30
$maxWaitMinutes = 30
$maxChecks = ($maxWaitMinutes * 60) / $checkInterval

for ($i = 0; $i -lt $maxChecks; $i++) {
    Start-Sleep -Seconds $checkInterval

    $status = az load test-run show `
        --load-test-resource $LoadTestingResourceName `
        --resource-group $ResourceGroup `
        --test-run-id $testRunId `
        --query "status" `
        -o tsv

    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)
    Write-Host "  Status: $status (elapsed: ${elapsed}min)"

    if ($status -in @("DONE", "FAILED", "CANCELLED")) {
        break
    }
}

# Get test results
Write-Host "`n📊 Retrieving test results..." -ForegroundColor Yellow
$results = az load test-run show `
    --load-test-resource $LoadTestingResourceName `
    --resource-group $ResourceGroup `
    --test-run-id $testRunId `
    -o json | ConvertFrom-Json

$resultsFile = Join-Path $OutputPath "test-results-$testRunId.json"
$results | ConvertTo-Json -Depth 10 | Out-File $resultsFile
Write-Host "  Raw results saved to: $resultsFile" -ForegroundColor Green

# Display summary
Write-Host "`n📈 Test Results Summary" -ForegroundColor Cyan
Write-Host "  Status: $($results.status)"
Write-Host "  Duration: $($results.duration) seconds"

if ($results.testResult) {
    $tr = $results.testResult
    Write-Host "`n  Performance Metrics:"
    Write-Host "    Total Requests:   $($tr.totalRequests)"
    Write-Host "    Failed Requests:  $($tr.errorCount)"
    Write-Host "    Avg Response:     $($tr.responseTimeAvg)ms"
    Write-Host "    P95 Response:     $($tr.responseTimeP95)ms"
    Write-Host "    P99 Response:     $($tr.responseTimeP99)ms"
    Write-Host "    Avg Throughput:   $($tr.throughput) RPS"
    Write-Host "    Error Rate:       $($tr.errorPercentage)%"
}

# Check pass/fail criteria
$failedCount = $results.passFailCriteria.passFailMetrics.Values | Where-Object { $_.result -eq "failed" } | Measure-Object | Select-Object -ExpandProperty Count

if ($failedCount -gt 0) {
    Write-Host "`n⚠️  Some pass/fail criteria were not met!" -ForegroundColor Yellow
    Write-Host "  Check the Azure Portal for detailed results."
} else {
    Write-Host "`n✅ All pass/fail criteria met!" -ForegroundColor Green
}

Write-Host "`n🔗 View in Azure Portal:"
$resourceId = az load show --name $LoadTestingResourceName --resource-group $ResourceGroup --query 'id' -o tsv
Write-Host "  https://portal.azure.com/#resource/$resourceId/tests" -ForegroundColor Blue
