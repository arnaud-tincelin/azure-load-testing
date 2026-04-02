#!/bin/bash
set -e

# Playwright Workspaces (Microsoft.LoadTestService/playwrightWorkspaces) is only
# available in: eastus, westus3, westeurope, eastasia.  When the main deployment
# region doesn't support it, we deploy to a separate resource group in westeurope.

PLAYWRIGHT_LOCATION="westeurope"
ENV_NAME="${AZURE_ENV_NAME}"
RG_NAME="rg-${ENV_NAME}-playwright"
WORKSPACE_NAME="pw-${ENV_NAME}"

echo "Deploying Playwright Workspace to ${PLAYWRIGHT_LOCATION}..."

az group create \
  --name "$RG_NAME" \
  --location "$PLAYWRIGHT_LOCATION" \
  --tags "azd-env-name=${ENV_NAME}" \
  --output none

az deployment group create \
  --resource-group "$RG_NAME" \
  --template-file ./infra/modules/playwright-testing.bicep \
  --parameters name="$WORKSPACE_NAME" tags="{\"azd-env-name\": \"${ENV_NAME}\"}" \
  --output none

echo "Playwright Workspace '${WORKSPACE_NAME}' deployed in ${RG_NAME} (${PLAYWRIGHT_LOCATION})"

# Get the storage account name from the deployment output
STORAGE_ACCOUNT=$(az deployment group show \
  --resource-group "$RG_NAME" \
  --name playwright-testing \
  --query "properties.outputs.storageAccountName.value" -o tsv 2>/dev/null || true)

# If we couldn't get it from deployment, derive it from the workspace name
if [ -z "$STORAGE_ACCOUNT" ]; then
  STORAGE_ACCOUNT=$(az storage account list --resource-group "$RG_NAME" --query "[0].name" -o tsv 2>/dev/null || true)
fi

# Assign Storage Blob Data Contributor to the current user
if [ -n "$STORAGE_ACCOUNT" ]; then
  USER_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || true)
  if [ -n "$USER_ID" ]; then
    STORAGE_ID=$(az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RG_NAME" --query id -o tsv)
    echo "Assigning Storage Blob Data Contributor role on ${STORAGE_ACCOUNT}..."
    az role assignment create \
      --assignee "$USER_ID" \
      --role "Storage Blob Data Contributor" \
      --scope "$STORAGE_ID" \
      --output none 2>/dev/null || echo "Role assignment already exists or insufficient permissions"
  fi
fi

# Store values for later use
azd env set AZURE_PLAYWRIGHT_TESTING_RESOURCE_NAME "$WORKSPACE_NAME"
azd env set AZURE_PLAYWRIGHT_TESTING_RESOURCE_GROUP "$RG_NAME"
