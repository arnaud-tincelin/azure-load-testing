# Marketplace Albums API — Azure Testing Demo

A .NET 9 API deployed on **Azure Container Apps**, with **Azure Load Testing** (JMeter) for performance testing and **Azure Playwright Testing** for functional API tests — all provisioned via `azd up`.

## What gets deployed

| Resource | Purpose |
|----------|---------|
| Azure Container Apps | Hosts the Albums API |
| Azure Container Registry | Stores the container image |
| Azure Load Testing | Runs JMeter load tests (up to 1000 RPS) |
| Azure Playwright Testing | Runs Playwright API tests at scale |

## Prerequisites

- [Azure Developer CLI (azd)](https://aka.ms/azure-dev/install)
- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [Node.js 20+](https://nodejs.org/) (for Playwright tests)
- Azure subscription

## Quick start

```bash
azd auth login
azd up
```

The API will be available at the URL shown in the deployment output.

To run locally: `cd albums-api && dotnet run` (serves on `http://localhost:5080`).

## API endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/albums` | List albums (filter: `?genre=Rock&maxPrice=15`) |
| `GET` | `/albums/{id}` | Get album by ID |
| `POST` | `/albums` | Create album |
| `PUT` | `/albums/{id}` | Update album |
| `DELETE` | `/albums/{id}` | Delete album |
| `GET` | `/cart/{sessionId}` | View cart |
| `POST` | `/cart/{sessionId}/items` | Add to cart |
| `DELETE` | `/cart/{sessionId}/items/{itemId}` | Remove from cart |
| `DELETE` | `/cart/{sessionId}` | Clear cart |
| `GET` | `/health` | Health check |

## Testing

### Load tests (JMeter + Azure Load Testing)

Ramps from 0 → 1000 RPS over 12 minutes with pass/fail criteria (P95 < 500ms, error rate < 1%).

```powershell
# Get deployment values
$env = azd env get-values | ConvertFrom-StringData

# Deploy and run
./albums-api/tests/load/deploy-load-test.ps1 `
    -ResourceGroup $env.AZURE_LOAD_TESTING_RESOURCE_GROUP `
    -LoadTestingResourceName $env.AZURE_LOAD_TESTING_RESOURCE_NAME `
    -TargetHost (($env.SERVICE_ALBUMS_API_ENDPOINT_URL -replace 'https://','') -replace '/$','') `
    -Protocol "https"

./albums-api/tests/load/run-load-test.ps1 `
    -ResourceGroup $env.AZURE_LOAD_TESTING_RESOURCE_GROUP `
    -LoadTestingResourceName $env.AZURE_LOAD_TESTING_RESOURCE_NAME
```

### Functional tests (Playwright)

API tests covering CRUD operations, cart flows, and end-to-end user journeys.

```bash
cd albums-api/tests/playwright
npm install

# Run locally
API_BASE_URL=https://<your-app-url> npx playwright test

# Run at scale on Azure Playwright Testing (20 parallel workers)
API_BASE_URL=https://<your-app-url> npx playwright test --config=playwright.service.config.ts
```

Results, traces, and reports are available in the Azure Playwright Testing portal.

## Project structure

```
├── azure.yaml                    # azd service config
├── infra/                        # Bicep templates
│   ├── main.bicep
│   └── modules/
│       ├── albums-api.bicep
│       ├── container-apps-environment.bicep
│       ├── container-registry.bicep
│       ├── load-testing.bicep
│       └── playwright-testing.bicep
└── albums-api/
    ├── Program.cs                # API entry point
    ├── Controllers/              # Albums + Cart endpoints
    ├── Models/                   # Album, CartItem
    ├── Services/                 # In-memory stores
    └── tests/
        ├── load/                 # JMeter test plan + scripts
        └── playwright/           # Playwright API tests
```
