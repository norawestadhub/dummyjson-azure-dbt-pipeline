-- 0) Velg riktig database og schema
USE DATABASE DUMMYJSON_PIPELINE;
USE SCHEMA RAW_STAGE;

-- 1) (Re-)opprett JSON-filformat
CREATE OR REPLACE FILE FORMAT RAW_JSON_FORMAT
  TYPE        = 'JSON'
  COMPRESSION = 'AUTO'
;

-- 2) (Re-)opprett Storage Integration mot Azure Blob
CREATE OR REPLACE STORAGE INTEGRATION MY_AZURE_INT
  TYPE                      = EXTERNAL_STAGE
  STORAGE_PROVIDER          = 'AZURE'
  ENABLED                   = TRUE
  AZURE_TENANT_ID           = '53b76c82-3f7e-4d92-9e49-7e1da18b8696'
  STORAGE_ALLOWED_LOCATIONS = ('azure://dummyjsonstorage01.blob.core.windows.net/raw')
;

-- 3) (Re-)opprett stage mot Azure Blob
CREATE OR REPLACE STAGE RAW_JSON_STAGE
  URL                 = 'azure://dummyjsonstorage01.blob.core.windows.net/raw'
  STORAGE_INTEGRATION = MY_AZURE_INT
  FILE_FORMAT         = RAW_JSON_FORMAT
;

-- 4) Opprett eksterne tabeller slik at metadata$filename er tilgjengelig
CREATE OR REPLACE EXTERNAL TABLE PRODUCTS_EXT (
  json_data VARIANT AS (VALUE),
  file_name STRING  AS (METADATA$FILENAME)
)
WITH LOCATION = @RAW_JSON_STAGE
FILE_FORMAT = (FORMAT_NAME = RAW_JSON_FORMAT)
PATTERN     = 'products_.*[.]json$'
AUTO_REFRESH = FALSE
;

CREATE OR REPLACE EXTERNAL TABLE CARTS_EXT (
  json_data VARIANT AS (VALUE),
  file_name STRING  AS (METADATA$FILENAME)
)
WITH LOCATION = @RAW_JSON_STAGE
FILE_FORMAT = (FORMAT_NAME = RAW_JSON_FORMAT)
PATTERN     = 'carts_.*[.]json$'
AUTO_REFRESH = FALSE
;

CREATE OR REPLACE EXTERNAL TABLE USERS_EXT (
  json_data VARIANT AS (VALUE),
  file_name STRING  AS (METADATA$FILENAME)
)
WITH LOCATION = @RAW_JSON_STAGE
FILE_FORMAT = (FORMAT_NAME = RAW_JSON_FORMAT)
PATTERN     = 'users_.*[.]json$'
AUTO_REFRESH = FALSE
;

-- 5) (Re-)opprett råtabeller med kolonner json_data + file_name
CREATE OR REPLACE TABLE PRODUCTS_RAW (
  json_data VARIANT,
  file_name STRING
);

CREATE OR REPLACE TABLE CARTS_RAW (
  json_data VARIANT,
  file_name STRING
);

CREATE OR REPLACE TABLE USERS_RAW (
  json_data VARIANT,
  file_name STRING
);

-- 6) Opprett eller oppdater task for inkrementell last
CREATE OR REPLACE TASK RAW_STAGE_LOAD_TASK
  WAREHOUSE = RAW_LOAD_WH
  SCHEDULE  = 'USING CRON 0 11 * * 1 UTC'
AS

  -- A) Load nye PRODUCTS
  INSERT INTO PRODUCTS_RAW (json_data, file_name)
  SELECT json_data, file_name
  FROM PRODUCTS_EXT
  WHERE file_name NOT IN (SELECT file_name FROM PRODUCTS_RAW)
  ;

  -- B) Load nye CARTS
  INSERT INTO CARTS_RAW (json_data, file_name)
  SELECT json_data, file_name
  FROM CARTS_EXT
  WHERE file_name NOT IN (SELECT file_name FROM CARTS_RAW)
  ;

  -- C) Load nye USERS
  INSERT INTO USERS_RAW (json_data, file_name)
  SELECT json_data, file_name
  FROM USERS_EXT
  WHERE file_name NOT IN (SELECT file_name FROM USERS_RAW)
  ;

-- 7) Aktiver tasken
ALTER TASK RAW_STAGE_LOAD_TASK RESUME;

-- 8) Sjekk at tasken er på plass
SHOW TASKS LIKE 'RAW_STAGE_LOAD_TASK';
