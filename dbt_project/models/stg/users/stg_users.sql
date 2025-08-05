{{ config(materialized='view') }}

WITH source AS (
    SELECT data
    FROM {{ ref('raw_users') }}
),

flattened AS (
    SELECT
        data:id AS user_id,
        data:firstName AS first_name,
        data:lastName AS last_name,
        data:email AS email,
        data:age AS age,
        data:gender AS gender,
        data:phone AS phone,
        data:address:city AS city,
        data:address:postalCode AS postal_code
    FROM source
)

SELECT * FROM flattened
