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

flattened as (
    select
      f.value:id::int                as cart_id,
      f.value:userId::int            as user_id,
      f.value:total::float           as total,
      f.value:discountedTotal::float as discounted_total
    from raw_data
      , lateral flatten(input => raw_data.carts_array) f
)

select * from flattened
