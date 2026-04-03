#!/bin/bash
set -e

# Playwright Workspaces only supports: eastus, westus3, westeurope, eastasia.
# Deploy to a dedicated resource group in westeurope.

PLAYWRIGHT_LOCATION="westeurope"
ENV_NAME="${AZURE_ENV_NAME}"
RG_NAME="rg-${ENV_NAME}-playwright"
WORKSPACE_NAME="pw-${ENV_NAME}"

USER_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || true)

echo "Deploying Playwright Workspace to ${PLAYWRIGHT_LOCATION}..."

az group create \
  --name "$RG_NAME" \
  --location "$PLAYWRIGHT_LOCATION" \
  --tags "azd-env-name=${ENV_NAME}" \
  --output none

az deployment group create \
  --resource-group "$RG_NAME" \
  --template-file ./infra/modules/app-testing.bicep \
  --parameters name="$WORKSPACE_NAME" tags="{\"azd-env-name\": \"${ENV_NAME}\"}" principalId="${USER_ID}" \
  --output none

echo "Playwright Workspace '${WORKSPACE_NAME}' deployed in ${RG_NAME} (${PLAYWRIGHT_LOCATION})"

# Get the dataplane URI for tests
DATAPLANE_URI=$(az deployment group show \
  --resource-group "$RG_NAME" \
  --name app-testing \
  --query "properties.outputs.dataplaneUri.value" -o tsv 2>/dev/null || true)

if [ -n "$DATAPLANE_URI" ]; then
  azd env set PLAYWRIGHT_SERVICE_URL "$DATAPLANE_URI"
  echo "PLAYWRIGHT_SERVICE_URL=${DATAPLANE_URI}"
fi

azd env set AZURE_PLAYWRIGHT_TESTING_RESOURCE_NAME "$WORKSPACE_NAME"
azd env set AZURE_PLAYWRIGHT_TESTING_RESOURCE_GROUP "$RG_NAME"
