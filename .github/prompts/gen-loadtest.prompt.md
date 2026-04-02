---
agent: Plan
description: 'Create a smoke test for Azure Load Testing'

tools: [execute/createAndRunTask, execute/runInTerminal, read/problems, read/readFile, edit, search, web/fetch, 'azure-mcp/*', todo, ms-azure-load-testing.microsoft-testing/create_load_test_script, ms-azure-load-testing.microsoft-testing/select_azure_load_testing_resource, ms-azure-load-testing.microsoft-testing/run_load_test_in_azure, ms-azure-load-testing.microsoft-testing/select_azure_load_test_run, ms-azure-load-testing.microsoft-testing/get_azure_load_test_run_insights]
model: 'Claude Opus 4.6'
---

You are an expert in creating load testing scenarios for web
services using Azure Load Testing and Apache JMeter.

## Goal

Create a plan for an Azure Load Testing scenario to measure
how the Albums API **and frontend** handle progressive load up
to 1000 requests per second.

## Context

- [azure.yaml](../../azure.yaml) — Azure Developer CLI configuration (deploys both `albums-api` and `albums-frontend`)
- [infra/main.bicep](../../infra/main.bicep) — Infrastructure as Code (outputs `SERVICE_ALBUMS_API_ENDPOINT_URL` and `SERVICE_ALBUMS_FRONTEND_ENDPOINT_URL`)
- [infra/modules/load-testing.bicep](../../infra/modules/load-testing.bicep) — Load Testing Bicep module
- [infra/modules/albums-frontend.bicep](../../infra/modules/albums-frontend.bicep) — Frontend Container App (nginx reverse-proxy to the API)
- [albums-api/Controllers/AlbumsController.cs](../../albums-api/Controllers/AlbumsController.cs) — Albums API endpoints
- [albums-api/Controllers/CartController.cs](../../albums-api/Controllers/CartController.cs) — Cart API endpoints
- [albums-frontend/index.html](../../albums-frontend/index.html) — Single-page frontend app
- [albums-frontend/nginx.conf.template](../../albums-frontend/nginx.conf.template) — Nginx config proxying `/albums` and `/cart` to the API


## Plan should cover

1. **Set up Azure Load Testing infrastructure** — Verify `azure.yaml` and `infra/` Bicep templates include the Azure Load Testing resource alongside the Container Apps deployment.
2. **Create JMeter test plan** — Generate `albums-api/tests/load/album-api-load-test.jmx` with thread groups for progressive ramping (0→100→500→1000 RPS), test scenarios covering all `/albums` endpoints (GET, POST, PUT, DELETE), and realistic user behavior patterns.
3. **Add frontend load scenarios** — Include thread groups that target the frontend URL (`SERVICE_ALBUMS_FRONTEND_ENDPOINT_URL`): load the homepage, browse albums through the nginx proxy, apply filters, open album details, and simulate cart interactions. This validates the nginx reverse-proxy and frontend serving under load alongside the API.
4. **Configure Azure Load Testing assets** — Create `albums-api/tests/load/load-test.yaml` with test configuration, environment variables (`SERVICE_ALBUMS_API_ENDPOINT_URL`, `SERVICE_ALBUMS_FRONTEND_ENDPOINT_URL`), and success criteria (response time <500ms, error rate <1%, throughput targets).
5. **Add deployment and execution scripts** — Create PowerShell scripts in `albums-api/tests/load/` for deploying load tests to Azure, executing tests, and retrieving results, plus update `README.md` with load testing documentation.
