-- 0) Velg database og schema
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
  STORAGE_ALLOWED_LOCATIONS = (
    'azure://dummyjsonstorage01.blob.core.windows.net/raw'
  )
;

-- 3) Inspeksjon av integrasjonen
DESCRIBE STORAGE INTEGRATION MY_AZURE_INT;

-- 4) (Re-)opprett stage mot Azure Blob ved å bruke integrasjonen
CREATE OR REPLACE STAGE RAW_JSON_STAGE
  URL                 = 'azure://dummyjsonstorage01.blob.core.windows.net/raw'
  STORAGE_INTEGRATION = MY_AZURE_INT
  FILE_FORMAT         = RAW_JSON_FORMAT
;

-- 5) (Re-)opprett råtabeller
-- CREATE OR REPLACE TABLE PRODUCTS_RAW (json_data VARIANT);
-- CREATE OR REPLACE TABLE CARTS_RAW    (json_data VARIANT);
-- CREATE OR REPLACE TABLE USERS_RAW    (json_data VARIANT);

-- 6) Test og hent filnavn
LIST @RAW_JSON_STAGE;
LIST @RAW_JSON_STAGE PATTERN = '.*products_.*[.]json$';
LIST @RAW_JSON_STAGE PATTERN = '.*carts_.*[.]json$';
LIST @RAW_JSON_STAGE PATTERN = '.*users_.*[.]json$';

-- 7) COPY til råtabeller med FORCE=FALSE for kun nye filer
COPY INTO PRODUCTS_RAW (json_data)
  FROM @RAW_JSON_STAGE
  FILE_FORMAT = RAW_JSON_FORMAT
  PATTERN     = '.*products_.*[.]json$'
  FORCE       = FALSE
  ON_ERROR    = 'CONTINUE'
;

COPY INTO CARTS_RAW (json_data)
  FROM @RAW_JSON_STAGE
  FILE_FORMAT = RAW_JSON_FORMAT
  PATTERN     = '.*carts_.*[.]json$'
  FORCE       = FALSE
  ON_ERROR    = 'CONTINUE'
;

COPY INTO USERS_RAW (json_data)
  FROM @RAW_JSON_STAGE
  FILE_FORMAT = RAW_JSON_FORMAT
  PATTERN     = '.*users_.*[.]json$'
  FORCE       = FALSE
  ON_ERROR    = 'CONTINUE'
;

-- 8) Opprett eller oppdater task som kjører hver mandag kl 11:00 UTC
CREATE OR REPLACE TASK RAW_STAGE_LOAD_TASK
  WAREHOUSE = RAW_LOAD_WH
  SCHEDULE  = 'USING CRON 0 11 * * 1 UTC'
AS
  COPY INTO PRODUCTS_RAW (json_data)
    FROM @RAW_JSON_STAGE
    FILE_FORMAT = RAW_JSON_FORMAT
    PATTERN     = '.*products_.*[.]json$'
    FORCE       = FALSE
    ON_ERROR    = 'CONTINUE'
  ;
  COPY INTO CARTS_RAW (json_data)
    FROM @RAW_JSON_STAGE
    FILE_FORMAT = RAW_JSON_FORMAT
    PATTERN     = '.*carts_.*[.]json$'
    FORCE       = FALSE
    ON_ERROR    = 'CONTINUE'
  ;
  COPY INTO USERS_RAW (json_data)
    FROM @RAW_JSON_STAGE
    FILE_FORMAT = RAW_JSON_FORMAT
    PATTERN     = '.*users_.*[.]json$'
    FORCE       = FALSE
    ON_ERROR    = 'CONTINUE'
  ;

-- 9) Aktiver tasken og verifiser
ALTER TASK RAW_STAGE_LOAD_TASK RESUME;
SHOW TASKS LIKE 'RAW_STAGE_LOAD_TASK';
