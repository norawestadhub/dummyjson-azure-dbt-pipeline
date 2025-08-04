# TimerTriggerAPI/shared.py
import logging, json, requests
from datetime import datetime, timezone
from azure.storage.blob import BlobServiceClient
from dbt_project.get_secrets import get_secret

logging.basicConfig(level=logging.INFO)

conn_str = get_secret("dummy-json-storage01-connection-string")
container_client = (
    BlobServiceClient.from_connection_string(conn_str)
    .get_container_client("raw")
)

api_endpoints = {
    "products": "https://dummyjson.com/products",
    "carts":    "https://dummyjson.com/carts",
    "users":    "https://dummyjson.com/users"
}

def run_pipeline():
    logging.info("Starter datainnhenting og opplasting...")
    results = {}
    for name, url in api_endpoints.items():
        try:
            resp = requests.get(url); resp.raise_for_status()
            data = resp.json()
            ts = datetime.now(timezone.utc).strftime("%Y-%m-%d_%H%M%S")
            blob_name = f"{name}_{ts}.json"
            container_client.upload_blob(
                name=blob_name,
                data=json.dumps(data, indent=2),
                overwrite=True
            )
            results[name] = {"status":"ok","uploaded":blob_name}
            logging.info(f"{name}: OK → {blob_name}")
        except Exception as e:
            logging.error(f"{name} feilet: {e}")
            results[name] = {"status":"error","message":str(e)}
    return json.dumps(results, ensure_ascii=False)
