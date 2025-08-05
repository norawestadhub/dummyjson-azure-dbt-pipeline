# 📦 Complete Data Pipeline Project

> **Automated ELT from REST API → Azure Blob → Snowflake**, with secure secrets, CI/CD, and dbt modeling.

---

## 📚 Table of Contents

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
11. [Snowflake Storage Integration](#snowflake-storage-integration)
12. [dbt Models Overview](#dbt-models-overview)
13. [Contact](#contact)
14. [License](#license)

---

## 📌 About This Project

This pipeline:

* **Fetches** JSON from three endpoints:

  * `https://dummyjson.com/products`
  * `https://dummyjson.com/carts`
  * `https://dummyjson.com/users`
* **Stores** each response as a timestamped `.json` file in an Azure Blob container
* **Automates** ingestion using Azure Functions (HTTP + Timer triggers)
* **Secures** secrets using Azure Key Vault
* **Schedules** a Snowflake Task (via CRON) to load blobs into raw tables
* **Implements** dbt transformations with star schema modeling
* **Uses** GitHub Actions for CI/CD and deployment automation

---

## ⚙️ Prerequisites

* **Python 3.10+**
* **Azure CLI** & **Azure Functions Core Tools (v4)**
* **Azurite** for local blob emulation:

  ```bash
  npm install -g azurite
  azurite
  ```
* **Git** with a GitHub repository
* (Optional) **VS Code** with Azure Functions extension

---

## 🛠️ Local Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/<your-org>/complete_data_pipeline_project_REBUILT.git
   cd complete_data_pipeline_project_REBUILT
   ```

2. **Create & activate a virtual environment**

   ```bash
   python -m venv .venv
   # Windows:
   .\.venv\Scripts\Activate.ps1
   # macOS/Linux:
   source .venv/bin/activate
   ```

3. **Install dependencies**

   ```bash
   pip install -r requirements.txt
   ```

4. **Start Azurite**

   ```bash
   azurite
   ```

5. **Configure local settings**
   Create/edit `local.settings.json`:

   ```json
   {
     "IsEncrypted": false,
     "Values": {
       "FUNCTIONS_WORKER_RUNTIME": "python",
       "AzureWebJobsStorage": "UseDevelopmentStorage=true",
       "DUMMY_JSON_STORAGE_CONNECTION_STRING": "UseDevelopmentStorage=true",
       "RAW_CONTAINER_NAME": "raw",
       "LOG_LEVEL": "INFO",
       "KEY_VAULT_URI": "https://<your-keyvault-name>.vault.azure.net/"
     }
   }
   ```

---

## ▶️ Running Locally

```bash
func start --verbose --port 7071
```

* **HTTP trigger**: [http://localhost:7071/api/run-pipeline](http://localhost:7071/api/run-pipeline)
* **Timer trigger**: Ensure `"runOnStartup": true` in `timerTrigger/function.json`

---

## ☁️ Deploying to Azure

1. **Login & set subscription**

   ```bash
   az login
   az account set --subscription <SUBSCRIPTION_ID>
   ```

2. **Publish to Azure Functions**

   ```bash
   func azure functionapp publish dummyjson-to-blob-func
   ```

3. **Configure app settings** in the Azure Portal:

   * `DUMMY_JSON_STORAGE_CONNECTION_STRING`
   * `KEY_VAULT_URI`
   * any other necessary secrets

---

## 🔄 CI/CD with GitHub Actions

Automated deployment pipeline defined in `.github/workflows/ci-cd.yml`:

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
        with:
          python-version: '3.11'
      - run: |
          pip install --upgrade pip
          pip install -r requirements.txt
      - uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      - run: |
          zip -r deployment.zip . -x ".git/*" -x ".venv/*"
      - run: |
          az functionapp deployment source config-zip \
            --resource-group data-dummyjson-demo-nwe-rg \
            --name dummyjson-to-blob-func \
            --src deployment.zip
```

---

## 📊 Monitoring & Alerts

### Azure Functions

* Enable **Application Insights**
* Add alert rules for failed executions

### Snowflake

* Monitor with `INFORMATION_SCHEMA.TASK_HISTORY`
* Optionally log to a custom table like `MONITORING.TASK_FAILURES`

---

## 🧱 Project Structure

```
complete_data_pipeline_project_REBUILT/
├── azure_functions/
│   └── IngestionFunction/
├── sql/
│   └── tasks/
│       └── 01_create_task.sql
├── dbt/
│   ├── models/
│   ├── tests/
│   └── dbt_project.yml
├── .github/
│   └── workflows/
│       └── ci-cd.yml
├── README.md
└── requirements.txt
```

---

## 🔐 Environment Variables & Secrets

| Variable                               | Description                            |
| -------------------------------------- | -------------------------------------- |
| `AzureWebJobsStorage`                  | Azure Functions blob connection string |
| `DUMMY_JSON_STORAGE_CONNECTION_STRING` | Storage connection string              |
| `RAW_CONTAINER_NAME`                   | Name of blob container (`raw`)         |
| `LOG_LEVEL`                            | Logging level (`INFO`, `DEBUG`, etc.)  |
| `KEY_VAULT_URI`                        | Azure Key Vault URI                    |
| `AZURE_CREDENTIALS`                    | GitHub Actions credentials             |

---

## ❄️ Snowflake Ingestion Task

Defined in `sql/01_create_task.sql`, this:

1. Creates an external stage pointing to the Azure Blob Storage `raw` container
2. Defines raw tables (`raw_products`, `raw_carts`, `raw_users`) with `VARIANT` type
3. Creates a Snowflake Task using CRON to load JSON files from blob
4. Automatically avoids duplicate ingestion (`FORCE = FALSE` by default)

Run manually with:

```bash
snowsql -f sql/01_create_task.sql
```

---

## 🧊 Snowflake Storage Integration

Using Azure AD integration instead of SAS tokens:

1. Create storage integration:

   ```sql
   CREATE OR REPLACE STORAGE INTEGRATION MY_AZURE_INT
     TYPE = EXTERNAL_STAGE
     STORAGE_PROVIDER = 'AZURE'
     ENABLED = TRUE
     AZURE_TENANT_ID = '<TENANT_ID>'
     STORAGE_ALLOWED_LOCATIONS = ('azure://<account>.blob.core.windows.net/raw');
   ```

2. Grant consent and assign `Storage Blob Data Reader` role to the Snowflake-managed identity.

3. Use the integration in your stage definition.

---

## 📦 dbt Models Overview

### Raw models (`raw_*`)

* Store raw JSON from Azure Blob using `VARIANT`
* Track file source using `file_name`

### Staging models (`stg_*`)

* Parse JSON arrays: `products`, `carts`, `users`
* Derive `ingest_date`
* Flatten nested structures
* Filter for latest file per entity

### Intermediate models (`int_*`)

* Cart metrics: `total_products`, `avg_price_per_item`, `cart_size`
* Product & user enrichment: `price_diff`, `age_group`, `full_name`

### Marts (fact & dimension)

* `fact_carts`: transactional fact table
* `dim_users`, `dim_products`: clean dimensional models
* Renamed from `marts_*` to `fact_/dim_` for star schema clarity

### Tests

* `not_null` on key fields
* `accepted_values` on enums (`gender`, `cart_size`, etc.)
* Relaxed tests on staging due to dummy data limitations

---

