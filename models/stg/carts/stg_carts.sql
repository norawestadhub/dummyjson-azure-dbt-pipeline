{{ config(materialized='view') }}

with raw_data as (
  select
    JSON_DATA:carts as carts_array
  from {{ ref('raw_carts') }}
),

flattened as (
  select
    f.value:id::int               as cart_id,
    f.value:userId::int           as user_id,
    f.value:total::float          as total,
    f.value:discountedTotal::float as discounted_total
  from raw_data
  , lateral flatten(input => raw_data.carts_array) as f
)

select * from flattened
