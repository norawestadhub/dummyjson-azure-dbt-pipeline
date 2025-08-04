import os
import json
import logging
from datetime import datetime, timezone

import requests
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.storage.blob import BlobServiceClient

# ──────────────────────────────────────────────────────────────────────────────
# Logger-oppsett
# ──────────────────────────────────────────────────────────────────────────────
log_level = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(level=log_level)
logger = logging.getLogger(__name__)

# ──────────────────────────────────────────────────────────────────────────────
# Key Vault‐konfigurasjon og get_secret‐funksjon
# ──────────────────────────────────────────────────────────────────────────────
KEY_VAULT_URI = os.getenv(
    "KEY_VAULT_URI",
    "https://dummyjsonkvdemonwe.vault.azure.net/"
)

_credential = DefaultAzureCredential()
_secret_client = SecretClient(vault_url=KEY_VAULT_URI, credential=_credential)

def get_secret(secret_name: str) -> str:
    """
    Henter en hemmelighet fra Azure Key Vault.
    """
    logger.debug("Henter secret '%s' fra Key Vault…", secret_name)
    secret = _secret_client.get_secret(secret_name)
    return secret.value

# ──────────────────────────────────────────────────────────────────────────────
# Blob Storage‐klient
# ──────────────────────────────────────────────────────────────────────────────
# Hent connection string fra Key Vault
_conn_str = get_secret("dummy-json-storage01-connection-string")

# Navn på container, kan overstyres via env-var
_container_name = os.getenv("RAW_CONTAINER_NAME", "raw")

_blob_service_client = BlobServiceClient.from_connection_string(_conn_str)
_container_client = _blob_service_client.get_container_client(_container_name)

# ──────────────────────────────────────────────────────────────────────────────
# API‐endepunkter
# ──────────────────────────────────────────────────────────────────────────────
api_endpoints = {
    "products": "https://dummyjson.com/products",
    "carts":    "https://dummyjson.com/carts",
    "users":    "https://dummyjson.com/users"
}

# ──────────────────────────────────────────────────────────────────────────────
# Kjerne‐funksjon: run_pipeline
# ──────────────────────────────────────────────────────────────────────────────
def run_pipeline() -> str:
    """
    Henter JSON fra hver API-endepunkt og laster dem opp som timestampede blobs.
    
    Returns:
        JSON-streng med status per endepunkt.
    """
    logger.info("Starter datainnhenting og opplasting…")
    results = {}

    for name, url in api_endpoints.items():
        try:
            logger.debug("Henter data fra %s", url)
            resp = requests.get(url, timeout=30)
            resp.raise_for_status()
            data = resp.json()

            ts = datetime.now(timezone.utc).strftime("%Y-%m-%d_%H%M%S")
            blob_name = f"{name}_{ts}.json"

            _container_client.upload_blob(
                name=blob_name,
                data=json.dumps(data, indent=2),
                overwrite=True
            )

            results[name] = {"status": "ok", "blob": blob_name}
            logger.info("OK: %s → %s", name, blob_name)

        except Exception as err:
            logger.error("Feilet for %s: %s", name, err, exc_info=True)
            results[name] = {"status": "error", "message": str(err)}

    return json.dumps(results, ensure_ascii=False)
