
-- Definér JSON-filformat
CREATE OR REPLACE FILE FORMAT RAW_JSON_FORMAT
  TYPE = 'JSON'
  COMPRESSION = 'AUTO';

-- Lag en External Stage mot Azure Blob (bytt ut med ditt account og SAS-token)CREATE OR REPLACE STAGE RAW_JSON_STAGE
  CREATE OR REPLACE STAGE RAW_JSON_STAGE
  URL = 'azure://dummyjsonstorage01.blob.core.windows.net/raw'
  CREDENTIALS = (
    AZURE_SAS_TOKEN = 'sv=2024-11-04&ss=bfqt&srt=sco&sp=rwdlacupyx&se=2029-08-04T18:23:15Z&st=2025-08-04T10:08:15Z&spr=https&sig=brJBRC1E%2BMdhgfqU3RZaLQdGGwRBtsyf1uscHI%2BAKp4%3D'
  )
  FILE_FORMAT = RAW_JSON_FORMAT
;

;
