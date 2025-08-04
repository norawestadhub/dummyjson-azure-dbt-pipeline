# Complete Data Pipeline Project

> **Automated ELT from REST API → Azure Blob → Snowflake**, with secure secrets, CI/CD, and monitoring.

---

## Table of Contents

1. [About This Project](#about-this-project)  
2. [Prerequisites](#prerequisites)  
3. [Local Setup](#local-setup)  
4. [Running Locally](#running-locally)  
5. [Deploying to Azure](#deploying-to-azure)  
6. [CI/CD with GitHub Actions](#cicd-with-github-actions)  
7. [Monitoring & Alerts](#monitoring--alerts)  
8. [Project Structure](#project-structure)  
9. [Environment Variables & Secrets](#environment-variables--secrets)  
10. [Snowflake Ingestion Task](#snowflake-ingestion-task)  

---

## About This Project

This pipeline:

- **Fetches** JSON from three endpoints:
  - `https://dummyjson.com/products`  
  - `https://dummyjson.com/carts`  
  - `https://dummyjson.com/users`  
- **Stores** each response as a timestamped `.json` in an Azure Blob container  
- **Automates** ingestion via Azure Functions (HTTP + Timer triggers), both locally and in Azure  
- **Secures** credentials in Azure Key Vault  
- **Schedules** a Snowflake Task (CRON) to load the blobs into Snowflake  
- **Implements** CI/CD with GitHub Actions and Git version control  

---

## Prerequisites

- **Python 3.10+**  
- **Azure CLI** & **Azure Functions Core Tools (v4)**  
- **Azurite** (local Blob emulator):  
  ```bash
  npm install -g azurite
  azurite
  ```  
- **Git** & a GitHub repo with a `main` branch  
- (Optional) **VS Code** with “Azure Functions” extension  

---

## Local Setup

1. **Clone the repository**  
   ```bash
   git clone https://github.com/<your-org>/complete_data_pipeline_project_REBUILT.git
   cd complete_data_pipeline_project_REBUILT
   ```

2. **Create & activate a virtual environment**  
   ```bash
   python -m venv .venv
   # Windows PowerShell:
   .\.venv\Scripts\Activate.ps1
   # macOS/Linux:
   source .venv/bin/activate
   ```

3. **Install dependencies**  
   ```bash
   pip install -r requirements.txt
   ```

4. **Start Azurite** (leave running)  
   ```bash
   azurite
   ```

5. **Configure local settings**  
   Edit `local.settings.json`:
   ```json
   {
     "IsEncrypted": false,
     "Values": {
       "FUNCTIONS_WORKER_RUNTIME": "python",
       "AzureWebJobsStorage": "UseDevelopmentStorage=true",
       "DUMMY_JSON_STORAGE_CONNECTION_STRING": "UseDevelopmentStorage=true",
       "RAW_CONTAINER_NAME": "raw",
       "LOG_LEVEL": "INFO",
       "KEY_VAULT_URI": "https://dummyjsonkvdemonwe.vault.azure.net/"
     }
   }
   ```

---

## Running Locally

```bash
func start --verbose --port 7071
```

- **HTTP trigger**  
  ```bash
  curl http://localhost:7071/api/run-pipeline
  ```
- **Timer trigger**  
  Ensure `"runOnStartup": true` in `timerTrigger/function.json`, then restart.

---

## Deploying to Azure

1. **Login & select subscription**  
   ```bash
   az login
   az account set --subscription <SUBSCRIPTION_ID>
   ```

2. **Publish Function App**  
   ```bash
   func azure functionapp publish dummyjson-to-blob-func
   ```

3. **Configure App Settings**  
   In the Azure Portal → Function App → **Configuration**, add:
   - `DUMMY_JSON_STORAGE_CONNECTION_STRING`  
   - `KEY_VAULT_URI`  
   - any other secrets  

---

## CI/CD with GitHub Actions

Automated build & deploy on `main`:

1. **Create a Service Principal**  
   ```bash
   az ad sp create-for-rbac \
     --name "github-actions-sp" \
     --role contributor \
     --scopes /subscriptions/<SUB_ID>/resourceGroups/data-dummyjson-demo-nwe-rg \
     --sdk-auth
   ```
2. **Add GitHub Secret**  
   - `AZURE_CREDENTIALS` ← JSON output from above

3. **Workflow**  
   The file `.github/workflows/azure-functions-deploy.yml`:
   ```yaml
   name: CI/CD – Azure Functions

   on:
     push:
       branches: [ main ]
     workflow_dispatch:

   jobs:
     build-and-deploy:
       runs-on: ubuntu-latest

       steps:
         - uses: actions/checkout@v3
         - uses: actions/setup-python@v4
           with: python-version: '3.11'
         - run: |
             pip install --upgrade pip
             pip install -r requirements.txt
         - uses: azure/login@v1
           with: creds: ${{ secrets.AZURE_CREDENTIALS }}
         - run: |
             zip -r deployment.zip . -x ".git/*" -x ".venv/*"
         - run: |
             az functionapp deployment source config-zip \
               --resource-group data-dummyjson-demo-nwe-rg \
               --name dummyjson-to-blob-func \
               --src deployment.zip
   ```


---

## Project Structure

```
complete_data_pipeline_project_REBUILT/
├─ .funcignore
├─ host.json
├─ local.settings.json
├─ requirements.txt
├─ shared.py          # pipeline logic
├─ get_secrets.py     # Key Vault helper
├─ httpTrigger/
│   ├─ function.json
│   └─ __init__.py
└─ timerTrigger/
    ├─ function.json
    └─ __init__.py
```

---

## Environment Variables & Secrets

| Name                                   | Purpose                                          |
|----------------------------------------|--------------------------------------------------|
| `AzureWebJobsStorage`                  | Functions storage connection                     |
| `DUMMY_JSON_STORAGE_CONNECTION_STRING` | Blob Storage connection (via Key Vault)          |
| `RAW_CONTAINER_NAME`                   | Blob container name (`raw`)                     |
| `LOG_LEVEL`                            | `INFO`, `DEBUG`, etc.                            |
| `KEY_VAULT_URI`                        | Your Key Vault URI                               |
| `AZURE_CREDENTIALS`                    | GitHub Actions Service Principal credentials     |

---

## Snowflake Ingestion Task

All ingestion logic is in `sql/01_create_task.sql`. It:

1. Creates a Snowflake **External Stage** pointing to Azure Blob (`raw` container)  
2. Defines raw tables (`PRODUCTS_RAW`, `CARTS_RAW`, `USERS_RAW`) as VARIANT  
3. Sets up a scheduled **Snowflake Task** (`RAW_STAGE_LOAD_TASK`) via CRON (Mondays at 09:00 UTC)  
4. Copies new JSON files from Blob into Snowflake automatically  

Run it once via SnowSQL or VS Code:
```bash
snowsql -f sql/01_create_task.sql
```
---

## Monitoring & Alerts

### Azure Functions

- **Enable** Application Insights on your Function App  
- **Alert Rule** in Azure Monitor:  
  - **Signal**: Function Execution Errors  
  - **Condition**: `> 0` errors over 5 minutes  
  - **Action Group**: Email / SMS / Teams / Webhook  

### Snowflake Task

1. **Log failures** via a monitoring table in Snowflake (`MONITORING.TASK_FAILURES`)  
2. **Create** a Snowflake Task that queries `INFORMATION_SCHEMA.TASK_HISTORY` for errors  
3. **Notify** via an external service (Azure Function, Logic App, or webhook) when failures are logged  
---
