-- 1) Velg database og schema
USE DATABASE DUMMYJSON_PIPELINE;
USE SCHEMA RAW_STAGE;

-- 2) (Re-)opprett JSON-filformat
CREATE OR REPLACE FILE FORMAT RAW_JSON_FORMAT
  TYPE       = 'JSON'
  COMPRESSION = 'AUTO'
;

-- 3) (Re-)opprett stage mot Azure Blob
CREATE OR REPLACE STAGE RAW_JSON_STAGE
  URL = 'azure://dummyjsonstorage01.blob.core.windows.net/raw'
  CREDENTIALS = (
    AZURE_SAS_TOKEN = 'sv=2024-11-04&ss=bfqt&srt=sco&sp=rwdlacupyx&se=2025-08-04T20:07:13Z&st=2025-08-04T11:52:13Z&spr=https&sig=8MTfueW7U%2BVVE7BPN35%2BwTqTg6KhlLVeCPyVwWIJJoI%3D'
  )
  FILE_FORMAT = RAW_JSON_FORMAT
;

-- 4) (Re-)opprett råtabeller
CREATE OR REPLACE TABLE PRODUCTS_RAW (json_data VARIANT);
CREATE OR REPLACE TABLE CARTS_RAW    (json_data VARIANT);
CREATE OR REPLACE TABLE USERS_RAW    (json_data VARIANT);

-- 5) Test at manuelle COPY fungerer
COPY INTO PRODUCTS_RAW (json_data)
  FROM @RAW_JSON_STAGE
  FILE_FORMAT = RAW_JSON_FORMAT
  PATTERN     = '.*raw/products_.*\.json$'
  ON_ERROR    = 'CONTINUE'
;
COPY INTO CARTS_RAW (json_data)
  FROM @RAW_JSON_STAGE
  FILE_FORMAT = RAW_JSON_FORMAT
  PATTERN     = '.*raw/carts_.*\.json$'
  ON_ERROR    = 'CONTINUE'
;
COPY INTO USERS_RAW (json_data)
  FROM @RAW_JSON_STAGE
  FILE_FORMAT = RAW_JSON_FORMAT
  PATTERN     = '.*raw/users_.*\.json$'
  ON_ERROR    = 'CONTINUE'
;

-- 6) Opprett eller oppdater en schedule-task som kjører hver mandag kl 09:00 UTC
CREATE OR REPLACE TASK RAW_STAGE_LOAD_TASK
  WAREHOUSE = RAW_LOAD_WH
  SCHEDULE  = 'USING CRON 0 11 * * 1 UTC'  -- mandag kl 11:00 UTC
AS
  COPY INTO PRODUCTS_RAW (json_data)
    FROM @RAW_JSON_STAGE
    FILE_FORMAT = RAW_JSON_FORMAT
    PATTERN     = '.*raw/products_.*\.json$'
    ON_ERROR    = 'CONTINUE'
  ;
  COPY INTO CARTS_RAW (json_data)
    FROM @RAW_JSON_STAGE
    FILE_FORMAT = RAW_JSON_FORMAT
    PATTERN     = '.*raw/carts_.*\.json$'
    ON_ERROR    = 'CONTINUE'
  ;
  COPY INTO USERS_RAW (json_data)
    FROM @RAW_JSON_STAGE
    FILE_FORMAT = RAW_JSON_FORMAT
    PATTERN     = '.*raw/users_.*\.json$'
    ON_ERROR    = 'CONTINUE'
  ;

-- 7) Aktiver tasken
ALTER TASK RAW_STAGE_LOAD_TASK RESUME;

-- 8) Sjekk at tasken er aktiv
SHOW TASKS LIKE 'RAW_STAGE_LOAD_TASK';

