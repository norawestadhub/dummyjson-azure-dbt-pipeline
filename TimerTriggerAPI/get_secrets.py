from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# 1. Sett Key Vault URI til din vault
KEY_VAULT_URI = "https://dummyjsonkvdemonwe.vault.azure.net/"

# 2. Opprett credential-objekt og SecretClient
credential = DefaultAzureCredential()
client = SecretClient(vault_url=KEY_VAULT_URI, credential=credential)

def get_secret(secret_name: str) -> str:
    """
    Henter en hemmelighet fra Key Vault.
    
    Args:
        secret_name: Navnet på secret i Key Vault, f.eks. 
                     'dummy-json-storage01-connection-string'
    Returns:
        Verdien av hemmeligheten som en streng.
    """
    secret = client.get_secret(secret_name)
    return secret.value

# Eksempel på bruk i shared.py:
if __name__ == "__main__":
    conn_str = get_secret("dummy-json-storage01-connection-string")
    print("Connection string hentet fra Key Vault:", conn_str)
