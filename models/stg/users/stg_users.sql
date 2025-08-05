{{ config(materialized='view') }}

WITH raw_data AS (
  SELECT JSON_DATA:users AS users_array
  FROM {{ ref('raw_users') }}
),

flattened AS (
  SELECT
    f.value:id::INT                       AS user_id,
    f.value:firstName::STRING             AS first_name,
    f.value:lastName::STRING              AS last_name,
    f.value:email::STRING                 AS email,
    f.value:age::INT                      AS age,
    f.value:gender::STRING                AS gender,
    f.value:phone::STRING                 AS phone,
    f.value:address:city::STRING          AS city,
    f.value:address:postalCode::STRING    AS postal_code,
    f.value:company:name::STRING          AS company_name  -- <–– ny linje
  FROM raw_data
    , LATERAL FLATTEN(input => raw_data.users_array) f
)

SELECT * 
FROM flattened
