# Complete Data Pipeline Project

**Table of Contents**  
- [About This Project](#about-this-project)  
- [Prerequisites](#prerequisites)  
- [Local Setup](#local-setup)  
- [Running Locally](#running-locally)  
- [Deploying to Azure](#deploying-to-azure)  
- [CI/CD with GitHub Actions](#cicd-with-github-actions)  
- [Project Structure](#project-structure)  
- [Environment Variables & Secrets](#environment-variables--secrets)  
- [Snowflake Ingestion Task](#snowflake-ingestion-task)  

---

## About This Project

This pipeline:

1. **Fetches** JSON data from three REST endpoints (`/products`, `/carts`, `/users`)  
2. **Stores** each response as a timestamped `.json` in an Azure Blob container  
3. **Automates** the data pull with Azure Functions (HTTP & Timer triggers), working both locally and in Azure  
4. **Secures** secrets (Blob connection string) in Azure Key Vault  
5. **Uses** a Snowflake Task (scheduled via CRON) to load blob files into Snowflake  
6. **Implements** CI/CD via GitHub Actions and version control in GitHub  

---

## Prerequisites

- **Python 3.10+**  
- **Azure CLI** & **Azure Functions Core Tools (v4)**  
- **Azurite** (local emulator)  
  ```bash
  npm install -g azurite
  azurite
Git & GitHub repo with a main branch

(Optional) VS Code with “Azure Functions” extension

Local Setup
Clone the repo

bash
Copy
Edit
git clone <your-repo-url>
cd complete_data_pipeline_project_REBUILT
Create & activate a virtual environment

bash
Copy
Edit
python -m venv .venv
# Windows (PowerShell):
.\.venv\Scripts\Activate.ps1
# macOS/Linux:
source .venv/bin/activate
Install dependencies
pip install -r requirements.txt
Start Azurite
azurite
Leave it running (Blob listen on http://127.0.0.1:10000).
Configure local settings
Edit local.settings.json:
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
Running Locally
func start --verbose --port 7071
HTTP trigger:
curl http://localhost:7071/api/run-pipeline
Timer trigger:
Ensure "runOnStartup": true in timerTrigger/function.json, then restart.

Deploying to Azure
Login & select subscription

az login
az account set --subscription <SUBSCRIPTION_ID>
Publish Function App
func azure functionapp publish dummyjson-to-blob-func
App Settings
In the Azure portal → Function App → Configuration, add your secrets (e.g. Blob connection string, Key Vault URI).

CI/CD with GitHub Actions
Automated build & deploy on main branch:

Create a Service Principal
az ad sp create-for-rbac \
  --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/<SUB_ID>/resourceGroups/data-dummyjson-demo-nwe-rg \
  --sdk-auth
Add GitHub Secret

AZURE_CREDENTIALS: the JSON output from the above command.

Workflow file
.github/workflows/azure-functions-deploy.yml handles checkout, install, login, zip & deploy.

Project Structure
complete_data_pipeline_project_REBUILT/
├─ .funcignore
├─ host.json
├─ local.settings.json
├─ requirements.txt
├─ shared.py          # pipeline logic
├─ get_secrets.py     # Azure Key Vault helper
├─ httpTrigger/
│   ├─ function.json
│   └─ __init__.py
└─ timerTrigger/
    ├─ function.json
    └─ __init__.py
Environment Variables & Secrets
AzureWebJobsStorage: Functions storage connection

DUMMY_JSON_STORAGE_CONNECTION_STRING: Blob Storage connection (via Key Vault)

RAW_CONTAINER_NAME: raw

LOG_LEVEL: INFO, DEBUG, etc.

KEY_VAULT_URI: Your Key Vault URL

AZURE_CREDENTIALS: GitHub Actions SP credentials

Snowflake Ingestion Task
All Snowflake ingestion logic is contained in sql/01_create_task.sql, which:

Creates a Snowflake external stage pointing to your Azure Blob (raw container)

Defines PRODUCTS_RAW, CARTS_RAW, USERS_RAW tables (VARIANT)

Sets up a scheduled Snowflake Task (RAW_STAGE_LOAD_TASK) using CRON (every Monday at 09:00 UTC)

Copies new JSON files from Blob into the raw tables automatically

Run 01_create_task.sql from VS Code (or SnowSQL) to deploy and activate the task.