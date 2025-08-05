{{ config(materialized='view') }}

with raw_with_date as (
    select
        json_data,
        file_name,
        to_date(
          left(split_part(file_name, '_', 2), 10),
          'YYYY-MM-DD'
        ) as ingest_date
    from {{ ref('raw_carts') }}
    where file_name is not null
),

latest as (
    select max(ingest_date) as last_date
    from raw_with_date
),

raw_data as (
    select json_data:carts as carts_array
    from raw_with_date r
    join latest       l
      on r.ingest_date = l.last_date
),

flattened_carts as (
    select
      f.value:id::int       as cart_id,
      f.value:userId::int   as user_id,
      f.value:products      as products_array
    from raw_data
      , lateral flatten(input => raw_data.carts_array) f
),

flattened_items as (
    select
      cart_id,
      user_id,
      i.value:productId::int as product_id,
      i.value:quantity::int  as quantity
    from flattened_carts
      , lateral flatten(input => flattened_carts.products_array) i
)

select
  cart_id,
  user_id,
  product_id,
  quantity
from flattened_items
