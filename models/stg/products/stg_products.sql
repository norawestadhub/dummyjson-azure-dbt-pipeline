{{ config(materialized='view') }}

WITH raw_data AS (
  SELECT
    JSON_DATA:products AS products_array
  FROM {{ ref('raw_products') }}
),

flattened AS (
  SELECT
    f.value:id::INT                AS product_id,
    f.value:title::STRING          AS title,
    f.value:description::STRING    AS description,
    f.value:price::FLOAT           AS price,
    f.value:discountPercentage::FLOAT AS discount_percentage,
    f.value:rating::FLOAT          AS rating,
    f.value:stock::INT             AS stock,
    f.value:brand::STRING          AS brand,
    f.value:category::STRING       AS category
  FROM raw_data
    , LATERAL FLATTEN(input => raw_data.products_array) f
)

SELECT *
FROM flattened
