
-- 3) create table

-- (Re-)opprett tabeller
CREATE OR REPLACE TABLE PRODUCTS_RAW (json_data VARIANT);
CREATE OR REPLACE TABLE CARTS_RAW    (json_data VARIANT);
CREATE OR REPLACE TABLE USERS_RAW    (json_data VARIANT);

-- Sjekk at du ser filer (skal vise hele URL)
LIST @RAW_JSON_STAGE;

-- COPY med enkelt mønster som bare leter etter "products_" et sted i URL
COPY INTO PRODUCTS_RAW (json_data)
FROM @RAW_JSON_STAGE
FILE_FORMAT = RAW_JSON_FORMAT
PATTERN = '.*products_.*\\.json'
ON_ERROR = 'CONTINUE'
;

COPY INTO CARTS_RAW (json_data)
FROM @RAW_JSON_STAGE
FILE_FORMAT = RAW_JSON_FORMAT
PATTERN = '.*carts_.*\\.json'
ON_ERROR = 'CONTINUE'
;

COPY INTO USERS_RAW (json_data)
FROM @RAW_JSON_STAGE
FILE_FORMAT = RAW_JSON_FORMAT
PATTERN = '.*users_.*\\.json'
ON_ERROR = 'CONTINUE'
;

-- Verifiser innlasting
SELECT
  (SELECT COUNT(*) FROM PRODUCTS_RAW) AS products_count,
  (SELECT COUNT(*) FROM CARTS_RAW)    AS carts_count,
  (SELECT COUNT(*) FROM USERS_RAW)    AS users_count
;
