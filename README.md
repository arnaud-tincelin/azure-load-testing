# Marketplace Albums API — Azure Testing Demo

A .NET 9 API and frontend deployed on **Azure Container Apps**, with **Azure Load Testing** (JMeter) for performance testing and **Azure Playwright Testing** for functional and browser tests — all provisioned via `azd up`.

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

Ramps from 0 → 1000 RPS over 12 minutes across 5 engine instances. Pass/fail criteria:

| Metric | Threshold |
|--------|-----------|
| Average response time | < 500 ms |
| P95 response time | < 500 ms |
| P99 response time | < 1000 ms |
| Error rate | < 1% |

Auto-stops if error rate exceeds 80% over a 60-second window.

**PowerShell:**
# Get deployment values
$env = azd env get-values | ConvertFrom-StringData

# Deploy and run
./tests/load/deploy-load-test.ps1 `
    -ResourceGroup $env.AZURE_LOAD_TESTING_RESOURCE_GROUP `
    -LoadTestingResourceName $env.AZURE_LOAD_TESTING_RESOURCE_NAME `
    -TargetHost (($env.SERVICE_ALBUMS_API_ENDPOINT_URL -replace 'https://','') -replace '/$','') `
    -Protocol "https"

./tests/load/run-load-test.ps1 `
    -ResourceGroup $env.AZURE_LOAD_TESTING_RESOURCE_GROUP `
    -LoadTestingResourceName $env.AZURE_LOAD_TESTING_RESOURCE_NAME
```

**Bash (Linux / macOS):**

```bash
# Get deployment values
eval $(azd env get-values | sed 's/^/export /')

# Deploy and run
TARGET_HOST=$(echo "$SERVICE_ALBUMS_API_ENDPOINT_URL" | sed 's|https://||;s|/$||')

./tests/load/deploy-load-test.sh \
    --resource-group "$AZURE_LOAD_TESTING_RESOURCE_GROUP" \
    --load-testing-resource "$AZURE_LOAD_TESTING_RESOURCE_NAME" \
    --target-host "$TARGET_HOST" \
    --protocol https

./tests/load/run-load-test.sh \
    --resource-group "$AZURE_LOAD_TESTING_RESOURCE_GROUP" \
    --load-testing-resource "$AZURE_LOAD_TESTING_RESOURCE_NAME"
```

### Functional tests (Playwright)

API tests covering CRUD, cart flows, health checks, and end-to-end user journeys. Browser tests run against the frontend across Chromium, Firefox, and WebKit when using Azure Playwright Testing.

```bash
cd tests/playwright
cp .env.example .env   # edit with your values
npm install

# Export deployment URLs (required for tests to reach the deployed app)
eval $(azd env get-values | sed 's/^/export /')

# Run locally (API + browser tests on Chromium)
npx playwright test

# Run at scale on Azure Playwright Testing (20 workers, 3 browsers)
npx playwright test --config=playwright.service.config.ts
```

Results, traces, and reports are available in the Azure Playwright Testing portal.

## Demo walkthrough

Step-by-step guide for presenting this demo:

### 1. Deploy the app

```bash
azd auth login
azd up
```

Note the output URLs for the API and frontend.

### 2. Explore the running app

- Open the **frontend URL** in a browser — browse albums, filter by genre/price, add to cart
- Open the **API URL** `/albums` to see the JSON response
- Try `/health` to verify the health endpoint

### 3. Run Playwright tests locally

```bash
cd tests/playwright && npm install
eval $(azd env get-values | sed 's/^/export /')
npx playwright test
npx playwright show-report
```

Walk through the HTML report: show passing API tests, cart tests, and browser tests with screenshots.

### 4. Run tests at scale on Azure Playwright Testing

```bash
npx playwright test --config=playwright.service.config.ts
```

Open the **Azure portal → Playwright Testing** workspace to show:
- Test results across Chromium, Firefox, and WebKit
- Parallel execution (20 workers)
- Traces, screenshots, and video artifacts

### 5. Run load tests

Deploy and run the JMeter load test (see commands in the [Load tests](#load-tests-jmeter--azure-load-testing) section above).

Open the **Azure portal → Load Testing** resource to show:
- Real-time test run dashboard
- Response time percentiles (P95/P99) and throughput
- Pass/fail criteria results
- Engine-level metrics across 5 instances

### 6. Review results

- Compare local vs. cloud test execution
- Show how pass/fail criteria gate deployments
- Highlight the architecture: Container Apps hosting + testing services as a complete inner loop

## Project structure

```
├── azure.yaml                    # azd service config
├── infra/                        # Bicep templates
│   ├── main.bicep
│   └── modules/
│       ├── albums-api.bicep
│       ├── albums-frontend.bicep
│       ├── container-apps-environment.bicep
│       ├── container-registry.bicep
│       ├── app-testing.bicep
│       └── load-testing.bicep
├── albums-api/
│   ├── Program.cs                # API entry point
│   ├── Controllers/              # Albums + Cart endpoints
│   ├── Models/                   # Album, CartItem
│   └── Services/                 # In-memory stores
├── albums-frontend/
│   ├── index.html                # SPA frontend
│   ├── nginx.conf.template       # Reverse proxy config
│   └── Dockerfile
└── tests/
    ├── load/                     # JMeter test plan + deploy/run scripts
    └── playwright/               # API, browser, health, and E2E tests
```
