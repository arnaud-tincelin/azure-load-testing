---
agent: Plan
description: 'Create a smoke test for Azure Load Testing'

tools: ['edit', 'search', 'execute/runInTerminal', 'execute/createAndRunTask', 'azure-mcp/*', 'azure-mcp/documentation', 'search/usages', 'read/problems', 'search/changes', 'web/fetch', 'todo' ]
model: 'Claude Opus 4.6'
---

You are an expert in creating load testing scenarios for web
services using Azure Load Testing and Apache JMeter.

## Goal

Create a plan for an Azure Load Testing scenario to measure
how the Albums API handles progressive load up to 1000
requests per second.

## Context

- [azure.yaml](../../azure.yaml) — Azure Developer CLI configuration
- [infra/main.bicep](../../infra/main.bicep) — Infrastructure as Code
- [infra/modules/load-testing.bicep](../../infra/modules/load-testing.bicep) — Load Testing Bicep module
- [albums-api/Controllers/AlbumsController.cs](../../albums-api/Controllers/AlbumsController.cs) — Albums API endpoints
- [albums-api/Controllers/CartController.cs](../../albums-api/Controllers/CartController.cs) — Cart API endpoints


## Plan should cover

1. **Set up Azure Load Testing infrastructure** — Verify `azure.yaml` and `infra/` Bicep templates include the Azure Load Testing resource alongside the Container Apps deployment.
2. **Create JMeter test plan** — Generate `albums-api/tests/load/album-api-load-test.jmx` with thread groups for progressive ramping (0→100→500→1000 RPS), test scenarios covering all `/albums` endpoints (GET, POST, PUT, DELETE), and realistic user behavior patterns.
3. **Configure Azure Load Testing assets** — Create `albums-api/tests/load/load-test.yaml` with test configuration, environment variables, and success criteria (response time <500ms, error rate <1%, throughput targets).
4. **Add deployment and execution scripts** — Create PowerShell scripts in `albums-api/tests/load/` for deploying load tests to Azure, executing tests, and retrieving results, plus update `README.md` with load testing documentation.
