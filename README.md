# Azure Load Testing Demo – Marketplace Albums API

A demo project showcasing **Azure Load Testing** driven by **GitHub Copilot** using MCP (Model Context Protocol) tools. The demo features a .NET Marketplace Albums API deployed on **Azure Container Apps** and progressively load-tested up to 1000 requests/second.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Azure                                │
│                                                             │
│  ┌──────────────┐     ┌────────────────────────────────┐   │
│  │    Azure     │     │    Azure Container Apps        │   │
│  │    Load      │────▶│                                │   │
│  │   Testing    │     │  ┌──────────────────────────┐  │   │
│  │  (JMeter)    │     │  │   Marketplace Albums API  │  │   │
│  └──────────────┘     │  │   (.NET 9, In-Memory)    │  │   │
│                       │  └──────────────────────────┘  │   │
│  ┌──────────────┐     └────────────────────────────────┘   │
│  │   Azure      │                    ▲                      │
│  │  Container   │────────────────────┘                      │
│  │  Registry    │                                           │
│  └──────────────┘                                           │
└─────────────────────────────────────────────────────────────┘
```

## API Endpoints

### Albums (Marketplace Items)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/albums` | List all albums (supports `?genre=Rock&maxPrice=15` filtering) |
| `GET` | `/albums/{id}` | Get a specific album by ID |
| `POST` | `/albums` | Add a new album to the marketplace |
| `PUT` | `/albums/{id}` | Update an existing album |
| `DELETE` | `/albums/{id}` | Remove an album from the marketplace |

### Cart

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/cart/{sessionId}` | View cart contents for a session |
| `POST` | `/cart/{sessionId}/items` | Add an album to the cart |
| `DELETE` | `/cart/{sessionId}/items/{itemId}` | Remove an item from the cart |
| `DELETE` | `/cart/{sessionId}` | Clear the entire cart |

### Health

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Health check endpoint |

## Prerequisites

- [Azure Developer CLI (azd)](https://aka.ms/azure-dev/install)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [Docker](https://www.docker.com/get-started)
- Azure subscription

## Quick Start

### 1. Deploy to Azure

```bash
# Login to Azure
azd auth login

# Initialize and deploy
azd up
```

This deploys:
- **Azure Container Registry** – stores the Docker image
- **Azure Container Apps Environment** – runs the API
- **Marketplace Albums API** – the .NET API container
- **Azure Load Testing** – for running load tests

### 2. Run the API locally

```bash
cd albums-api
dotnet run
```

The API will be available at `http://localhost:5080`.

### 3. Run load tests

#### Deploy the load test to Azure

```powershell
# Get deployment outputs from azd
$env = azd env get-values | ConvertFrom-StringData
$loadTestResource = $env.AZURE_LOAD_TESTING_RESOURCE_NAME
$resourceGroup = $env.AZURE_LOAD_TESTING_RESOURCE_GROUP
$apiHost = ($env.SERVICE_ALBUMS_API_ENDPOINT_URL -replace 'https://', '') -replace '/$', ''

# Deploy the test configuration
./albums-api/tests/load/deploy-load-test.ps1 `
    -ResourceGroup $resourceGroup `
    -LoadTestingResourceName $loadTestResource `
    -TargetHost $apiHost `
    -Protocol "https"
```

#### Run the load test

```powershell
./albums-api/tests/load/run-load-test.ps1 `
    -ResourceGroup $resourceGroup `
    -LoadTestingResourceName $loadTestResource
```

## Load Test Configuration

The JMeter test plan (`album-api-load-test.jmx`) progressively ramps load across 3 phases:

| Phase | Duration | Target RPS | Description |
|-------|----------|------------|-------------|
| Warm-up | 2 minutes | 0 → 100 RPS | GET /albums only |
| Ramp-up | 5 minutes | 100 → 500 RPS | Mixed read/write traffic |
| Peak Load | 5 minutes | 500 → 1000 RPS | Full traffic mix |

**Traffic distribution (Phases 2 & 3):**
- 40% – `GET /albums` (list all albums)
- 35% – `GET /albums/{id}` (get album by ID)
- 15% – `POST /albums` (add new album)
- 10% – `GET /cart/{sessionId}` (view cart)

### Success Criteria

| Metric | Threshold |
|--------|-----------|
| P95 Response Time | < 500ms |
| P99 Response Time | < 1000ms |
| Error Rate | < 1% |
| Min Throughput | ≥ 100 RPS |

## Using with GitHub Copilot (MCP Tools)

This demo is designed to be driven by GitHub Copilot using the following prompt:

```
You are an expert in creating load testing scenarios for web services using
Azure Load Testing and Apache JMeter.

The goal is to create an Azure Load Testing scenario to measure how the Albums
API is handling progressive load up to 1000 requests per second.

Steps:
1. Set up Azure Load Testing infrastructure
2. Create JMeter test plan with thread groups for progressive ramping (0-100-500-1000 RPS)
3. Configure Azure Load Testing assets with success criteria
4. Add deployment and execution scripts
```

## Project Structure

```
azure-load-testing/
├── azure.yaml                          # AZD service configuration
├── infra/
│   ├── main.bicep                      # Main infrastructure template
│   ├── main.parameters.json            # Deployment parameters
│   ├── abbreviations.json              # Azure resource abbreviations
│   └── modules/
│       ├── container-registry.bicep    # Azure Container Registry
│       ├── container-apps-environment.bicep  # Container Apps Env
│       ├── albums-api.bicep            # Container App definition
│       └── load-testing.bicep          # Azure Load Testing resource
└── albums-api/
    ├── Program.cs                      # Application entry point
    ├── MarketplaceApi.csproj           # .NET project file
    ├── Dockerfile                      # Container image definition
    ├── Controllers/
    │   ├── AlbumsController.cs         # Albums CRUD endpoints
    │   └── CartController.cs           # Shopping cart endpoints
    ├── Models/
    │   ├── Album.cs                    # Album model
    │   └── CartItem.cs                 # Cart item model
    ├── Services/
    │   ├── AlbumStore.cs               # In-memory album store
    │   └── CartStore.cs                # In-memory cart store
    └── tests/load/
        ├── album-api-load-test.jmx     # JMeter test plan
        ├── load-test.yaml              # Azure Load Testing config
        ├── deploy-load-test.ps1        # Deploy test to Azure
        └── run-load-test.ps1           # Run test and get results
```
