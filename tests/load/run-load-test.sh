#!/usr/bin/env bash
#
# Runs the Albums API load test and retrieves results.
#
# Usage:
#   ./run-load-test.sh \
#       --resource-group <rg> \
#       --load-testing-resource <name> \
#       [--test-id albums-api-load-test]

set -euo pipefail

TEST_ID="albums-api-load-test"

while [[ $# -gt 0 ]]; do
  case $1 in
    --resource-group)          RESOURCE_GROUP="$2"; shift 2 ;;
    --load-testing-resource)   LOAD_TESTING_RESOURCE="$2"; shift 2 ;;
    --test-id)                 TEST_ID="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

: "${RESOURCE_GROUP:?--resource-group is required}"
: "${LOAD_TESTING_RESOURCE:?--load-testing-resource is required}"

TEST_RUN_ID="${TEST_ID}-run-$(date +%Y%m%d-%H%M%S)"

echo "Starting load test run..."
echo "  Test ID     : $TEST_ID"
echo "  Test Run ID : $TEST_RUN_ID"

# Ensure the az load extension is installed
if ! az extension show --name load --query name -o tsv 2>/dev/null | grep -q load; then
  if ! python3 -m pip --version &>/dev/null; then
    echo "Error: python3-pip is required to install the 'az load' extension." >&2
    echo "Install it with: sudo apt-get install -y python3-pip" >&2
    exit 1
  fi
  az extension add --name load --only-show-errors
fi

# Start the test run
echo -e "\nStarting test run '$TEST_RUN_ID'..."
az load test-run create \
    --test-id "$TEST_ID" \
    --test-run-id "$TEST_RUN_ID" \
    --load-test-resource "$LOAD_TESTING_RESOURCE" \
    --resource-group "$RESOURCE_GROUP" \
    --display-name "Albums API Load Test - $(date '+%Y-%m-%d %H:%M')" \
    --description "Progressive load test run" \
    --no-wait

echo "Test run started. Polling for completion..."

# Poll for completion
MAX_WAIT_SECONDS=$((20 * 60))
POLL_INTERVAL=30
ELAPSED=0

while true; do
    sleep $POLL_INTERVAL
    ELAPSED=$((ELAPSED + POLL_INTERVAL))

    STATUS=$(az load test-run show \
        --test-run-id "$TEST_RUN_ID" \
        --load-test-resource "$LOAD_TESTING_RESOURCE" \
        --resource-group "$RESOURCE_GROUP" \
        --query "status" -o tsv 2>/dev/null || echo "UNKNOWN")

    ELAPSED_MIN=$(awk "BEGIN {printf \"%.1f\", $ELAPSED/60}")
    echo "  [${ELAPSED_MIN} min] Status: $STATUS"

    if [[ "$STATUS" == "DONE" || "$STATUS" == "FAILED" || "$STATUS" == "CANCELLED" ]]; then
        break
    fi

    if [[ $ELAPSED -ge $MAX_WAIT_SECONDS ]]; then
        echo -e "\nTimed out waiting for test run to complete (waited 20 minutes)."
        echo "Check status in the Azure portal."
        break
    fi
done

case "$STATUS" in
    DONE)      echo -e "\nTest run completed!" ;;
    FAILED)    echo -e "\nTest run failed!" ;;
    CANCELLED) echo -e "\nTest run was cancelled." ;;
esac

# Show results
echo -e "\n--- Test Run Results ---"
az load test-run metrics list \
    --test-run-id "$TEST_RUN_ID" \
    --load-test-resource "$LOAD_TESTING_RESOURCE" \
    --resource-group "$RESOURCE_GROUP" \
    --metric-namespace LoadTestRunMetrics \
    --metric-id VirtualUsers,RequestsPerSecond,ResponseTime,ErrorPercentage \
    -o table 2>/dev/null || true

# Download results
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results"
mkdir -p "$RESULTS_DIR"

echo -e "\nDownloading detailed results to $RESULTS_DIR..."
az load test-run download-files \
    --test-run-id "$TEST_RUN_ID" \
    --load-test-resource "$LOAD_TESTING_RESOURCE" \
    --resource-group "$RESOURCE_GROUP" \
    --path "$RESULTS_DIR" \
    --force 2>/dev/null || true

echo -e "\nResults saved to: $RESULTS_DIR"
echo "Test Run ID: $TEST_RUN_ID"
