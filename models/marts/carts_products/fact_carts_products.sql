{{ config(materialized='table') }}

with enriched as (
  select
    icd.cart_id,
    icd.product_id,
    icd.quantity,
    -- multiply against the non-null discounted_price from dim_products
    icd.quantity * dp.discounted_price as item_total
  from {{ ref('int_cart_details') }} as icd
  join {{ ref('dim_products') }}    as dp
    on icd.product_id = dp.id
)

select * from enriched
