{{ config(materialized='view') }}

WITH raw_data AS (
  -- Hent JSON-array med alle carts
  SELECT
    JSON_DATA:carts AS carts_array
  FROM {{ ref('raw_carts') }}
),

flattened_carts AS (
  -- Én rad per cart, med products-array med items
  SELECT
    f.value:id::INT       AS cart_id,
    f.value:userId::INT   AS user_id,
    f.value:products      AS products_array
  FROM raw_data
    , LATERAL FLATTEN(input => raw_data.carts_array) f
),

flattened_items AS (
  -- Én rad per item i hver cart
  SELECT
    cart_id,
    user_id,
    i.value:productId::INT AS product_id,
    i.value:quantity::INT  AS quantity
  FROM flattened_carts
    , LATERAL FLATTEN(input => flattened_carts.products_array) i
)

SELECT
  cart_id,
  user_id,
  product_id,
  quantity
FROM flattened_items
