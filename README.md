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
11. [Snowflake Storage Integration](#snowflake-storage-integration)

---

## About This Project

This pipeline:

* **Fetches** JSON from three endpoints:

  * `https://dummyjson.com/products`
  * `https://dummyjson.com/carts`
  * `https://dummyjson.com/users`
* **Stores** each response as a timestamped `.json` in an Azure Blob container
* **Automates** ingestion via Azure Functions (HTTP + Timer triggers), both locally and in Azure
* **Secures** credentials in Azure Key Vault
* **Schedules** a Snowflake Task (CRON) to load the blobs into Snowflake
* **Implements** CI/CD with GitHub Actions and Git version control

---

## Prerequisites

* **Python 3.10+**
* **Azure CLI** & **Azure Functions Core Tools (v4)**
* **Azurite** (local Blob emulator):

  ```bash
  npm install -g azurite
  azurite
  ```
* **Git** & a GitHub repo with a `main` branch
* (Optional) **VS Code** with “Azure Functions” extension

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

* **HTTP trigger**

  ```bash
  curl http://localhost:7071/api/run-pipeline
  ```
* **Timer trigger**
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

   * `DUMMY_JSON_STORAGE_CONNECTION_STRING`
   * `KEY_VAULT_URI`
   * any other secrets

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

   * `AZURE_CREDENTIALS` ← JSON output from above

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

## Monitoring & Alerts

### Azure Functions

* **Enable** Application Insights on your Function App
* **Alert Rule** in Azure Monitor:

  * **Signal**: Function Execution Errors
  * **Condition**: `> 0` errors over 5 minutes
  * **Action Group**: Email / SMS / Teams / Webhook

### Snowflake Task

1. **Log failures** via a monitoring table in Snowflake (`MONITORING.TASK_FAILURES`)
2. **Create** a Snowflake Task that queries `INFORMATION_SCHEMA.TASK_HISTORY` for errors
3. **Notify** via an external service (Azure Function, Logic App, or webhook) when failures are logged

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

| Name                                   | Purpose                                      |
| -------------------------------------- | -------------------------------------------- |
| `AzureWebJobsStorage`                  | Functions storage connection                 |
| `DUMMY_JSON_STORAGE_CONNECTION_STRING` | Blob Storage connection (via Key Vault)      |
| `RAW_CONTAINER_NAME`                   | Blob container name (`raw`)                  |
| `LOG_LEVEL`                            | `INFO`, `DEBUG`, etc.                        |
| `KEY_VAULT_URI`                        | Your Key Vault URI                           |
| `AZURE_CREDENTIALS`                    | GitHub Actions Service Principal credentials |

---

## Snowflake Ingestion Task

All ingestion logic is in `sql/01_create_task.sql`. It:

1. Creates a Snowflake **External Stage** pointing to Azure Blob (`raw` container)
2. Defines raw tables (`PRODUCTS_RAW`, `CARTS_RAW`, `USERS_RAW`) as VARIANT
3. Sets up a scheduled **Snowflake Task** (`RAW_STAGE_LOAD_TASK`) via CRON (Mondays at 11:00 UTC)
4. Copies new JSON files from Blob into Snowflake automatically. By default, `COPY INTO` only ingests files not previously loaded (`FORCE = FALSE`); to reload older files use `FORCE = TRUE`.

Run it once via SnowSQL or VS Code:

```bash
snowsql -f sql/01_create_task.sql
```

---

## Snowflake Storage Integration

We’ve introduced a dedicated Azure AD–based Storage Integration in Snowflake to replace SAS tokens:

1. **Create Storage Integration** in `sql/01_create_task.sql`:

   ```sql
   CREATE OR REPLACE STORAGE INTEGRATION MY_AZURE_INT
     TYPE                      = EXTERNAL_STAGE
     STORAGE_PROVIDER          = 'AZURE'
     ENABLED                   = TRUE
     AZURE_TENANT_ID           = '<YOUR_TENANT_ID>'
     STORAGE_ALLOWED_LOCATIONS = (
       'azure://<account>.blob.core.windows.net/raw'
     );
   ```

2. **Consent & Role Assignment**:

   * Retrieve `AZURE_CONSENT_URL` and `AZURE_MULTI_TENANT_APP_NAME` via:

     ```sql
     DESCRIBE STORAGE INTEGRATION MY_AZURE_INT;
     ```
   * Open the `AZURE_CONSENT_URL` in a browser as a Global Admin to provision the service principal in your tenant.
   * Assign the generated service principal **Storage Blob Data Reader** role on the `raw` container in Azure.

3. **Use New Stage**:

   ```sql
   CREATE OR REPLACE STAGE RAW_JSON_STAGE
     URL                 = 'azure://<account>.blob.core.windows.net/raw'
     STORAGE_INTEGRATION = MY_AZURE_INT
     FILE_FORMAT         = RAW_JSON_FORMAT;
   ```
# 🧩 Dummy JSON Azure → Snowflake Data Pipeline with dbt

This project demonstrates an end-to-end data pipeline using Azure, Snowflake, and dbt. It ingests JSON data from Azure Blob Storage, processes it through Snowflake tasks and stages, and models it into analytics-ready tables using dbt.

## 🚀 Overview

- Ingestion via Azure Functions (HTTP & timer triggers)
- Secrets management via Azure Key Vault
- CI/CD automation with GitHub Actions
- Data landing in Snowflake using external stages
- Transformation and modeling with dbt
- Fully tested pipeline and models for production-quality standards

---

## 🔄 Pipeline Flow

1. **Trigger**: Timer-based or HTTP-triggered Azure Function starts the ingestion.
2. **Load**: New JSON files from blob storage are moved to Snowflake using a Snowflake task.
3. **Store**: Raw data is stored in `raw_*` tables as `VARIANT` columns.
4. **Transform**: dbt parses, transforms, and structures the data into dimensional models.
5. **Test**: dbt tests ensure data quality and schema integrity.

---

## 🧠 dbt Models Overview

### Raw models (`raw_*`)
- Store original JSON content from blob storage in `VARIANT` format.
- Includes metadata such as `file_name` to track ingestion source.

### Staging models (`stg_*`)
- Parses JSON arrays for:
  - `products`, `carts`, and `users`.
- Implements:
  - Latest-file filtering using `file_name` timestamps.
  - `ingest_date` exposure for lineage and tracking.
  - JSON flattening into structured tabular columns.

### Intermediate models (`int_*`)
- Business logic transformations, including:
  - Cart metrics like `total_products`, `total_quantity`, `avg_price_per_item`, and `cart_size`.
  - Product-level calculations such as `is_in_stock`, `price_difference`, etc.
  - User enhancements like `full_name` and `age_group` classification.

### Marts (fact & dimension tables)
- Final analytics-ready models designed for star schema:
  - `fact_carts`: central fact table for cart events.
  - `dim_products`, `dim_users`: clean dimension tables.
- Renamed from `marts_*` to `fact_/dim_` for clarity and best practices.

### Schema Tests
- `not_null` constraints on key fields.
- `accepted_values` checks for:
  - `cart_size`, `stock_status`, `age_group`, and `gender`.
- Relaxed or removed `unique`/`foreign key` tests in staging to accommodate dummy source data.

---

## 📁 Repository Structure

├── azure_functions/
│ └── IngestionFunction/
├── sql/
│ └── tasks/
│ └── 01_create_task.sql
├── dbt/
│ ├── models/
│ ├── tests/
│ └── dbt_project.yml
├── .github/
│ └── workflows/
│ └── ci-cd.yml
├── README.md
└── requirements.txt


---

## 📦 Tech Stack

- **Azure Functions** (Python)
- **Azure Key Vault** (Secrets)
- **Azure Blob Storage**
- **Snowflake** (Warehouse, Stages, Tasks)
- **dbt** (Data transformation and testing)
- **GitHub Actions** (CI/CD)

---

## ✅ How to Run Locally

1. Clone repo and create a `.env` file for Azure Function secrets.
2. Set up Snowflake and create necessary roles, warehouses, and stages.
3. Deploy Azure Functions and connect to Blob Storage.
4. Run `dbt seed`, `dbt run`, and `dbt test` to transform and validate data.

---

## 📬 Contact

Have questions or want to learn more about the project?

Feel free to reach out via [LinkedIn](https://linkedin.com/) or [email@example.com](mailto:email@example.com).

---

## 📄 License

MIT License.

This eliminates manual SAS tokens and centralizes Azure AD–based authentication for Snowflake loads.
