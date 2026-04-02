<#
.SYNOPSIS
    Runs the Albums API load test and retrieves results.

.DESCRIPTION
    Starts a test run for the previously deployed load test, polls for completion,
    and displays the results summary.

.PARAMETER ResourceGroup
    The Azure resource group containing the Load Testing resource.

.PARAMETER LoadTestingResourceName
    The name of the Azure Load Testing resource.

.PARAMETER TestId
    The test ID to run (default: albums-api-load-test).
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$LoadTestingResourceName,

    [string]$TestId = "albums-api-load-test"
)

$ErrorActionPreference = "Stop"
$testRunId = "$TestId-run-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

Write-Host "Starting load test run..." -ForegroundColor Cyan
Write-Host "  Test ID     : $TestId"
Write-Host "  Test Run ID : $testRunId"

# Ensure the az load extension is installed
az extension add --name load --only-show-errors 2>$null

# Start the test run
Write-Host "`nStarting test run '$testRunId'..." -ForegroundColor Yellow
az load test-run create `
    --test-id $TestId `
    --test-run-id $testRunId `
    --load-test-resource $LoadTestingResourceName `
    --resource-group $ResourceGroup `
    --display-name "Albums API Load Test - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" `
    --description "Progressive load test run" `
    --no-wait

Write-Host "Test run started. Polling for completion..." -ForegroundColor Yellow

# Poll for completion
$maxWaitMinutes = 20
$pollIntervalSeconds = 30
$elapsed = 0

do {
    Start-Sleep -Seconds $pollIntervalSeconds
    $elapsed += $pollIntervalSeconds

    $status = az load test-run show `
        --test-run-id $testRunId `
        --load-test-resource $LoadTestingResourceName `
        --resource-group $ResourceGroup `
        --query "status" -o tsv 2>$null

    $elapsedMin = [math]::Round($elapsed / 60, 1)
    Write-Host "  [$elapsedMin min] Status: $status"

} while ($status -notin @("DONE", "FAILED", "CANCELLED") -and $elapsed -lt ($maxWaitMinutes * 60))

if ($status -eq "DONE") {
    Write-Host "`nTest run completed!" -ForegroundColor Green
} elseif ($status -eq "FAILED") {
    Write-Host "`nTest run failed!" -ForegroundColor Red
} elseif ($status -eq "CANCELLED") {
    Write-Host "`nTest run was cancelled." -ForegroundColor Yellow
} else {
    Write-Host "`nTimed out waiting for test run to complete (waited $maxWaitMinutes minutes)." -ForegroundColor Red
    Write-Host "Check status in the Azure portal."
}

# Show results
Write-Host "`n--- Test Run Results ---" -ForegroundColor Cyan
az load test-run metrics list `
    --test-run-id $testRunId `
    --load-test-resource $LoadTestingResourceName `
    --resource-group $ResourceGroup `
    --metric-namespace LoadTestRunMetrics `
    --metric-id VirtualUsers,RequestsPerSecond,ResponseTime,ErrorPercentage `
    -o table 2>$null

# Download results
$resultsDir = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "results"
if (-not (Test-Path $resultsDir)) {
    New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null
}

Write-Host "`nDownloading detailed results to $resultsDir..." -ForegroundColor Yellow
az load test-run download-files `
    --test-run-id $testRunId `
    --load-test-resource $LoadTestingResourceName `
    --resource-group $ResourceGroup `
    --path $resultsDir `
    --force 2>$null

Write-Host "`nResults saved to: $resultsDir" -ForegroundColor Green
Write-Host "Test Run ID: $testRunId"
