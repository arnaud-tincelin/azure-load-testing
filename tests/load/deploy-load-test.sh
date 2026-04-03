#!/usr/bin/env bash
#
# Deploys the JMeter load test to Azure Load Testing.
#
# Usage:
#   ./deploy-load-test.sh \
#       --resource-group <rg> \
#       --load-testing-resource <name> \
#       --target-host <host> \
#       [--protocol https] \
#       [--port 443]

set -euo pipefail

PROTOCOL="https"
PORT="443"

while [[ $# -gt 0 ]]; do
  case $1 in
    --resource-group)          RESOURCE_GROUP="$2"; shift 2 ;;
    --load-testing-resource)   LOAD_TESTING_RESOURCE="$2"; shift 2 ;;
    --target-host)             TARGET_HOST="$2"; shift 2 ;;
    --protocol)                PROTOCOL="$2"; shift 2 ;;
    --port)                    PORT="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

: "${RESOURCE_GROUP:?--resource-group is required}"
: "${LOAD_TESTING_RESOURCE:?--load-testing-resource is required}"
: "${TARGET_HOST:?--target-host is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_ID="albums-api-load-test"
CONFIG_FILE="$SCRIPT_DIR/load-test.yaml"

echo "Deploying load test to Azure Load Testing..."
echo "  Resource Group : $RESOURCE_GROUP"
echo "  ALT Resource   : $LOAD_TESTING_RESOURCE"
echo "  Target Host    : $TARGET_HOST"
echo "  Protocol       : $PROTOCOL"
echo "  Port           : $PORT"

# Ensure the az load extension is installed
echo -e "\nChecking Azure CLI load extension..."
if ! az extension show --name load --query name -o tsv 2>/dev/null | grep -q load; then
  if ! python3 -m pip --version &>/dev/null; then
    echo "Error: python3-pip is required to install the 'az load' extension." >&2
    echo "Install it with: sudo apt-get install -y python3-pip" >&2
    exit 1
  fi
  az extension add --name load --only-show-errors
fi

# Prepare temp directory with config and test plan (az load resolves testPlan path relative to config)
TEMP_DIR="$(mktemp -d)"
sed "s|\${SERVICE_ALBUMS_API_ENDPOINT_URL}|${TARGET_HOST}|g" "$CONFIG_FILE" > "$TEMP_DIR/load-test.yaml"
cp "$SCRIPT_DIR/album-api-load-test.jmx" "$TEMP_DIR/"

# Create or update the load test using the config file
echo -e "\nCreating/updating load test '$TEST_ID'..."
if az load test show --test-id "$TEST_ID" --load-test-resource "$LOAD_TESTING_RESOURCE" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
  az load test update \
      --test-id "$TEST_ID" \
      --load-test-resource "$LOAD_TESTING_RESOURCE" \
      --resource-group "$RESOURCE_GROUP" \
      --load-test-config-file "$TEMP_DIR/load-test.yaml" \
      --env HOST="$TARGET_HOST" PORT="$PORT" PROTOCOL="$PROTOCOL"
else
  az load test create \
      --test-id "$TEST_ID" \
      --load-test-resource "$LOAD_TESTING_RESOURCE" \
      --resource-group "$RESOURCE_GROUP" \
      --load-test-config-file "$TEMP_DIR/load-test.yaml" \
      --env HOST="$TARGET_HOST" PORT="$PORT" PROTOCOL="$PROTOCOL"
fi

rm -rf "$TEMP_DIR"

echo -e "\nLoad test '$TEST_ID' deployed successfully!"
echo "You can now run it with:"
echo "  ./run-load-test.sh --resource-group $RESOURCE_GROUP --load-testing-resource $LOAD_TESTING_RESOURCE"
