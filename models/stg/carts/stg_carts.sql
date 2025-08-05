{{ config(materialized='view') }}

WITH source AS (
    SELECT data
    FROM {{ ref('raw_products') }}
),

flattened AS (
    SELECT
        data:id AS product_id,
        data:title AS title,
        data:description AS description,
        data:price AS price,
        data:category AS category,
        data:rating AS rating,
        data:stock AS stock
    FROM source
)

SELECT * FROM flattened
