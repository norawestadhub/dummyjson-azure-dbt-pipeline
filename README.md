# Complete Data Pipeline Project

**Innhold**

* [Om prosjektet](#om-prosjektet)
* [Forutsetninger](#forutsetninger)
* [Oppsett lokalt](#oppsett-lokalt)
* [Kjøring lokalt](#kjøring-lokalt)
* [Deploy til Azure](#deploy-til-azure)
* [CI/CD med GitHub Actions](#cicd-med-github-actions)
* [Mappestruktur](#mappestruktur)
* [Miljøvariabler / secrets](#miljøvariabler--secrets)

---

## Om prosjektet

Dette er en Azure Functions-basert data-pipeline som:

1. Henter JSON-data fra tre API-endepunkter (`products`, `carts`, `users`)
2. Laster opp dataene som timestampede `.json`-filer til en Azure Blob-container
3. Støtter både HTTP-trigger (manuell kjøring) og Timer-trigger (planlagt kjøring)

---

## Forutsetninger

* **Node.js & npm**
* **Azurite** (lokal Azure Storage emulator)

  ```bash
  npm install -g azurite  
  azurite  
  ```
* **Python 3.10+** (anbefalt for Azure Functions)
* **Azure Functions Core Tools (v4)**
* **Azure CLI**
* (Valgfritt) VS Code med “Azure Functions”-extension
* **Git**-repo med `main`-branch

---

## Oppsett lokalt

1. **Clone repo**

   ```bash
   git clone <din-repo-URL>  
   cd complete_data_pipeline_project_REBUILT  
   ```

2. **Opprett & aktiver virtuelt miljø**

   ```bash
   python -m venv .venv  
   # Windows (PowerShell):  
   .\.venv\Scripts\Activate.ps1  
   # macOS/Linux:  
   source .venv/bin/activate  
   ```

3. **Installer dependencies**

   ```bash
   pip install -r requirements.txt  
   ```

4. **Start Azurite**

   ```bash
   azurite  
   ```

   La terminalen stå åpen (Blob på `http://127.0.0.1:10000`).

5. **Konfigurer environment vars**
   Rediger `local.settings.json` i roten:

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

## Kjøring lokalt

```bash
func start --verbose --port 7071  
```

* **HTTP-trigger**

  ```bash
  curl http://localhost:7071/api/run-pipeline  
  ```
* **Timer-trigger**
  Kjør umiddelbart med `"runOnStartup": true` i `timerTrigger/function.json`, restart host.

---

## Deploy til Azure

1. **Logg inn**

   ```bash
   az login  
   az account set --subscription <SUBSCRIPTION_ID>  
   ```
2. **Deploy**

   ```bash
   func azure functionapp publish dummyjson-to-blob-func  
   ```
3. **App Settings**
   Sett opp secrets i Azure-portalen under Configuration → Application settings.

---

## CI/CD med GitHub Actions

Automatiser deploy med en service principal og GitHub Actions:

### 1) Opprett Service Principal i Azure

```bash
az login  
az account set --subscription <SUBSCRIPTION_ID>  
az ad sp create-for-rbac \  
  --name "github-actions-sp" \  
  --role contributor \  
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/data-dummyjson-demo-nwe-rg \  
  --sdk-auth  
```

Kopier API-utdata fra kommandoen.

### 2) Legg inn GitHub Secrets

* `AZURE_CREDENTIALS`: Lim inn hele JSON-blokken fra SP-kommandoen.

### 3) Workflow-definisjon

Legg til `.github/workflows/azure-functions-deploy.yml` i repo:

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
          python -m pip install --upgrade pip  
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

Etter push vil workflow kjøre, autentisere via SP og deploye koden.

---

## Mappestruktur

```text
complete_data_pipeline_project_REBUILT/  
├─ .funcignore  
├─ host.json  
├─ local.settings.json  
├─ requirements.txt  
├─ shared.py  
├─ get_secrets.py  
├─ httpTrigger/  
│   ├─ function.json  
│   └─ __init__.py  
└─ timerTrigger/  
    ├─ function.json  
    └─ __init__.py  
```

---

## Miljøvariabler / secrets

* **AzureWebJobsStorage**: Lokal eller produksjons-connection string
* **DUMMY\_JSON\_STORAGE\_CONNECTION\_STRING**: Blob Storage string fra Key Vault
* **RAW\_CONTAINER\_NAME**: Navnet på container (`raw`)
* **LOG\_LEVEL**: Logger-nivå (`INFO`, `DEBUG`)
* **KEY\_VAULT\_URI**: URI til Key Vault
* **AZURE\_CREDENTIALS**: GitHub Secret for Service Principal-auth

## Snowflake External Stage & COPY INTO

I dette repoet ligger SQL-skriptene som laster rå JSON-filer fra Azure Blob Storage over til Snowflake. De tre filene du trenger å kjøre, i denne rekkefølgen, ligger i `sql/`-mappen:

1. **01_create_database_and_schema.sql**  
   Oppretter database `DUMMYJSON_PIPELINE` og schema `RAW_STAGE`:
   ```sql
   CREATE DATABASE IF NOT EXISTS DUMMYJSON_PIPELINE;
   USE DATABASE DUMMYJSON_PIPELINE;

   CREATE SCHEMA IF NOT EXISTS RAW_STAGE;
   USE SCHEMA RAW_STAGE;
CREATE OR REPLACE FILE FORMAT RAW_JSON_FORMAT
  TYPE = 'JSON' COMPRESSION = 'AUTO';

CREATE OR REPLACE STAGE RAW_JSON_STAGE
  URL = 'azure://dummyjsonstorage01.blob.core.windows.net/raw'
  CREDENTIALS=(AZURE_SAS_TOKEN='?sv=<din-SAS-token>')
  FILE_FORMAT = RAW_JSON_FORMAT;
  USE DATABASE DUMMYJSON_PIPELINE;
USE SCHEMA RAW_STAGE;

CREATE OR REPLACE TABLE PRODUCTS_RAW (json_data VARIANT);
CREATE OR REPLACE TABLE CARTS_RAW    (json_data VARIANT);
CREATE OR REPLACE TABLE USERS_RAW    (json_data VARIANT);

COPY INTO PRODUCTS_RAW (json_data)
FROM @RAW_JSON_STAGE
FILE_FORMAT = RAW_JSON_FORMAT
PATTERN     = '.*products_.*\.json'
ON_ERROR    = 'CONTINUE'
;

COPY INTO CARTS_RAW (json_data)
FROM @RAW_JSON_STAGE
FILE_FORMAT = RAW_JSON_FORMAT
PATTERN     = '.*carts_.*\.json'
ON_ERROR    = 'CONTINUE'
;

COPY INTO USERS_RAW (json_data)
FROM @RAW_JSON_STAGE
FILE_FORMAT = RAW_JSON_FORMAT
PATTERN     = '.*users_.*\.json'
ON_ERROR    = 'CONTINUE'
;

SELECT
  (SELECT COUNT(*) FROM PRODUCTS_RAW) AS products_count,
  (SELECT COUNT(*) FROM CARTS_RAW)    AS carts_count,
  (SELECT COUNT(*) FROM USERS_RAW)    AS users_count
;