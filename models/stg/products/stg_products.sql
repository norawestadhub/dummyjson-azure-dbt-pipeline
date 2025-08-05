{{ config(materialized='view') }}

with raw_with_date as (
    select
        json_data,
        file_name,
        to_date(
          left( split_part(file_name, '_', 2), 10 ),
          'YYYY-MM-DD'
        ) as ingest_date
    from {{ ref('raw_products') }}
    where file_name is not null
),

latest as (
    select max(ingest_date) as last_date
    from raw_with_date
),

raw_data as (
    select json_data:products as products_array
    from raw_with_date r
    join latest       l on r.ingest_date = l.last_date
),

flattened as (
    select
      f.value:id::int                   as product_id,
      f.value:title::string             as title,
      f.value:description::string       as description,
      f.value:price::float              as price,
      f.value:discountPercentage::float as discount_percentage,
      f.value:rating::float             as rating,
      f.value:stock::int                as stock,
      f.value:brand::string             as brand,
      f.value:category::string          as category
    from raw_data
      , lateral flatten(input => raw_data.products_array) f
)

select * from flattened
