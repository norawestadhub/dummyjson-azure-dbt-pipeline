import sys
import os
import logging
import requests
from datetime import datetime, timezone
from azure.storage.blob import BlobServiceClient
import json

# Konfigurer logging
logging.basicConfig(level=logging.INFO)

# Legg til prosjektets rotmappe for import
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Importer Azure Functions-pakken
import azure.functions as func

# Importer funksjonen for å hente secrets
from dbt_project.get_secrets import get_secret

# Hent Blob Storage-tilkobling fra Key Vault
blob_connection_string = get_secret("dummy-json-storage01-connection-string")

# Sett miljøvariabel for AzureWebJobsStorage om ikke allerede satt
if "AzureWebJobsStorage" not in os.environ:
    os.environ["AzureWebJobsStorage"] = blob_connection_string

# Initialiser BlobServiceClient
blob_service_client = BlobServiceClient.from_connection_string(blob_connection_string)
container_client = blob_service_client.get_container_client("raw")

# Definer API-endepunktene
api_endpoints = {
    "products": "https://dummyjson.com/products",
    "carts":    "https://dummyjson.com/carts",
    "users":    "https://dummyjson.com/users"
}

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("HTTP-trigger mottatt – henter og laster opp data...")

    results = {}
    for name, url in api_endpoints.items():
        try:
            resp = requests.get(url)
            resp.raise_for_status()
            data = resp.json()
            logging.info(f"Hentet data fra {url}")
        except Exception as e:
            logging.error(f"Feil ved henting av '{name}': {e}")
            results[name] = {"status": "error", "message": str(e)}
            continue

        timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d_%H%M%S")
        blob_name = f"{name}_{timestamp}.json"
        blob_data = json.dumps(data, indent=2)

        try:
            container_client.upload_blob(name=blob_name, data=blob_data, overwrite=True)
            logging.info(f"Lastet opp '{blob_name}' til container 'raw'")
            results[name] = {"status": "ok", "uploaded": blob_name}
        except Exception as e:
            logging.error(f"Feil ved opplasting av '{blob_name}': {e}")
            results[name] = {"status": "error", "message": str(e)}

    return func.HttpResponse(
        json.dumps(results, indent=2, ensure_ascii=False),
        status_code=200,
        mimetype="application/json"
    )

# Lokal kjøring
if __name__ == "__main__":
    # Mock request for lokal test
    class DummyReq:
        def __init__(self):
            self.method = "GET"
            self.url = ""
    response = main(DummyReq())
    print(response.get_body().decode('utf-8'))
