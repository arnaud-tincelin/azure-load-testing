---
agent: Plan
description: 'Create Playwright tests for Azure App Testing'
tools: [execute/createAndRunTask, execute/runInTerminal, read/problems, read/readFile, edit, search, web/fetch, 'azure-mcp/*', todo]
model: 'Claude Opus 4.6'
---

You are an expert in writing end-to-end tests using Playwright
and running them at scale with Playwright Workspaces
(Azure App Testing). You cover both API-level and browser-level
testing.

## Goal

Create a plan for adding Playwright-based API **and browser**
tests to the Albums Marketplace and running them at scale using
Playwright Workspaces cloud browsers.

## Context

### Infrastructure & deployment
- [azure.yaml](../../azure.yaml) — Azure Developer CLI configuration (deploys both `albums-api` and `albums-frontend`)
- [infra/main.bicep](../../infra/main.bicep) — Infrastructure as Code (outputs `SERVICE_ALBUMS_API_ENDPOINT_URL` and `SERVICE_ALBUMS_FRONTEND_ENDPOINT_URL`)
- [infra/modules/albums-frontend.bicep](../../infra/modules/albums-frontend.bicep) — Frontend Container App (nginx reverse-proxy, receives `apiUrl` from the API module)
- [infra/modules/playwright-testing.bicep](../../infra/modules/playwright-testing.bicep) — Playwright Workspace with `reporting: 'Enabled'` and a Storage Account for trace/screenshot artifacts
- [infra/hooks/postprovision.sh](../../infra/hooks/postprovision.sh) — Deploys Playwright Workspaces to a supported region and assigns Storage Blob Data Contributor for reporting

### API
- [albums-api/Controllers/AlbumsController.cs](../../albums-api/Controllers/AlbumsController.cs) — Albums API endpoints
- [albums-api/Controllers/CartController.cs](../../albums-api/Controllers/CartController.cs) — Cart API endpoints

### Frontend
- [albums-frontend/index.html](../../albums-frontend/index.html) — Single-page app (uses `data-testid` attributes for Playwright selectors)
- [albums-frontend/nginx.conf.template](../../albums-frontend/nginx.conf.template) — Nginx config that proxies `/albums` and `/cart` to the API
- [albums-frontend/Dockerfile](../../albums-frontend/Dockerfile) — Frontend container image

### Playwright configuration
- [albums-api/tests/playwright/playwright.config.ts](../../albums-api/tests/playwright/playwright.config.ts) — Local config with `chromium` project for browser tests and an API project for headless request tests
- [albums-api/tests/playwright/playwright.service.config.ts](../../albums-api/tests/playwright/playwright.service.config.ts) — Cloud config (uses `@azure/playwright` + `DefaultAzureCredential`, `@azure/playwright/reporter` for Azure portal reporting)

### Test suites
- [albums-api/tests/playwright/tests/albums.spec.ts](../../albums-api/tests/playwright/tests/albums.spec.ts) — Album CRUD API tests (uses `request` context)
- [albums-api/tests/playwright/tests/cart.spec.ts](../../albums-api/tests/playwright/tests/cart.spec.ts) — Cart API flow tests (uses `request` context)
- [albums-api/tests/playwright/tests/e2e-journey.spec.ts](../../albums-api/tests/playwright/tests/e2e-journey.spec.ts) — End-to-end API journey tests (uses `request` context)
- [albums-api/tests/playwright/tests/frontend.spec.ts](../../albums-api/tests/playwright/tests/frontend.spec.ts) — Browser tests for the frontend (uses `page` context — navigates to the frontend, tests filters, album detail, cart UI)

## Plan should cover

1. **Verify infrastructure** — Confirm `infra/modules/playwright-testing.bicep` provisions a `Microsoft.LoadTestService/playwrightWorkspaces` resource with `regionalAffinity: 'Enabled'` and `reporting: 'Enabled'`, deployed to a supported region (eastus, westus3, westeurope, or eastasia) via the postprovision hook. Verify the Storage Account has CORS configured for `https://trace.playwright.dev`.
2. **Verify frontend deployment** — Confirm the frontend Container App is deployed alongside the API, that `SERVICE_ALBUMS_FRONTEND_ENDPOINT_URL` is set, and that nginx proxies `/albums` and `/cart` requests to the API.
3. **Install dependencies** — Run `npm install` in `albums-api/tests/playwright/` to install `@playwright/test`, `@azure/playwright`, `@azure/identity`, and `npx playwright install chromium` for browser tests.
4. **Run API tests locally** — Execute `npx playwright test tests/albums.spec.ts tests/cart.spec.ts tests/e2e-journey.spec.ts` against the deployed or local API.
5. **Run browser tests locally** — Execute `npx playwright test tests/frontend.spec.ts` with `SERVICE_ALBUMS_FRONTEND_ENDPOINT_URL` set. These tests use `page` context (browser mode) to navigate the frontend, interact with UI elements via `data-testid` selectors, and verify end-to-end flows through the nginx proxy.
6. **Run all tests at scale in Azure** — Set `PLAYWRIGHT_SERVICE_URL` to the workspace endpoint, authenticate with `az login`, then run `npx playwright test --config=playwright.service.config.ts --workers=20` to execute both API and browser tests on cloud-hosted browsers via `createAzurePlaywrightConfig` with `DefaultAzureCredential`.
7. **Review results & Azure Reporting** — Check the `@azure/playwright/reporter` output in the Azure portal (Playwright Workspaces blade). Review test results, traces, screenshots, and video artifacts. Verify the Storage Account is receiving trace files and that traces are viewable via `trace.playwright.dev`.
