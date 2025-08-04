USE DATABASE DUMMYJSON_PIPELINE;
USE SCHEMA RAW_STAGE;

-- Sjekk LIST igjen
LIST @RAW_JSON_STAGE;

-- Kopier products
COPY INTO PRODUCTS_RAW (json_data)
FROM @RAW_JSON_STAGE
FILE_FORMAT = RAW_JSON_FORMAT
PATTERN     = '.*raw/products_.*\\.json$'
ON_ERROR    = 'CONTINUE'
;

-- Kopier carts
COPY INTO CARTS_RAW (json_data)
FROM @RAW_JSON_STAGE
FILE_FORMAT = RAW_JSON_FORMAT
PATTERN     = '.*raw/carts_.*\\.json$'
ON_ERROR    = 'CONTINUE'
;

-- Kopier users
COPY INTO USERS_RAW (json_data)
FROM @RAW_JSON_STAGE
FILE_FORMAT = RAW_JSON_FORMAT
PATTERN     = '.*raw/users_.*\\.json$'
ON_ERROR    = 'CONTINUE'
;

-- Verifiser
SELECT
  (SELECT COUNT(*) FROM PRODUCTS_RAW) AS products_count,
  (SELECT COUNT(*) FROM CARTS_RAW)    AS carts_count,
  (SELECT COUNT(*) FROM USERS_RAW)    AS users_count
;
