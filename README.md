# Complete Data Pipeline Project

**Innhold**  
- [Om prosjektet](#om-prosjektet)  
- [Forutsetninger](#forutsetninger)  
- [Oppsett lokalt](#oppsett-lokalt)  
- [Kjøring lokalt](#kjøring-lokalt)  
- [Deploy til Azure](#deploy-til-azure)  
- [Mappestruktur](#mappestruktur)  
- [Miljøvariabler / secrets](#miljøvariabler--secrets)  

---

## Om prosjektet

Dette er en Azure Functions-basert data-pipeline som:  
1. Henter JSON-data fra tre API-endepunkter (`products`, `carts`, `users`)  
2. Laster opp dataene som timestampede `.json`-filer til en Azure Blob-container  
3. Støtter både HTTP-trigger (manuell kjøring) og Timer-trigger (planlagt kjøring)  

---

## Forutsetninger

- **Node.js & npm**  
- **Azurite** (lokal Azure Storage emulator)  
  ```bash
  npm install -g azurite
Python 3.8+ (anbefalt 3.10 for Azure Functions)

Azure Functions Core Tools (v4)

Azure CLI (om du vil deploye fra terminal)

(Valgfritt) VS Code med “Azure Functions”-extension

En eksisterende Azure Function App (for produksjons-deploy)

Key Vault med secret dummy-json-storage01-connection-string

Oppsett lokalt
Clone repo

bash
Copy
Edit
git clone <din-repo-URL>
cd complete_data_pipeline_project_REBUILT
Opprett & aktiver virtuelt miljø

bash
Copy
Edit
python -m venv .venv
# Windows (PowerShell):
.\.venv\Scripts\Activate.ps1
# macOS/Linux:
source .venv/bin/activate
Installer dependencies

bash
Copy
Edit
pip install -r requirements.txt
Start Azurite

bash
Copy
Edit
azurite
La terminalen stå åpen — Azurite gir deg lokal Blob-endpoint på http://127.0.0.1:10000.

Konfigurer environment vars
Rediger local.settings.json (ligger i roten) om nødvendig:

json
Copy
Edit
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
Kjøring lokalt
bash
Copy
Edit
func start --verbose --port 7071
HTTP-trigger
Kall endpointen med CURL eller Postman:

bash
Copy
Edit
curl http://localhost:7071/api/run-pipeline
Timer-trigger
Sjekk loggene for å se når den kjører neste gang (hver mandag kl. 09:00 UTC).

Deploy til Azure
Logg inn med Azure CLI eller i VS Code:

bash
Copy
Edit
az login
(Valgfritt) Bygg & test lokalt

bash
Copy
Edit
func start
Deploy med Azure Functions Core Tools:

bash
Copy
Edit
func azure functionapp publish <NAVN_PÅ_DIN_FUNCTION_APP>
Eller bruk VS Code: høyreklikk på Function App i Azure-panelet → “Deploy to Function App”.

Mappestruktur
text
Copy
Edit
complete_data_pipeline_project_REBUILT/
├─ .funcignore
├─ host.json
├─ local.settings.json
├─ requirements.txt
├─ shared.py                  # Felles pipeline-logikk
├─ get_secrets.py             # Key Vault-henting
├─ httpTrigger/
│   ├─ function.json
│   └─ __init__.py
└─ timerTrigger/
    ├─ function.json
    └─ __init__.py
Miljøvariabler / secrets
AzureWebJobsStorage
Storage-connection string for Functions-runtime

DUMMY_JSON_STORAGE_CONNECTION_STRING
Connection string til Blob-storage (hentes fra Key Vault)

RAW_CONTAINER_NAME
Navnet på Blob-container (f.eks. raw)

LOG_LEVEL
Logger-nivå (INFO, DEBUG osv.)

KEY_VAULT_URI
URI til Key Vault, f.eks. https://dummyjsonkvdemonwe.vault.azure.net/

