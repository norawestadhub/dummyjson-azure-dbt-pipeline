{{ config(materialized='table') }}

with base as (
  select
    product_id,
    title,
    category,
    brand,
    price,
    discount_percentage,
    discounted_price,
    rating,
    stock,
    stock_status
  from {{ ref('int_products') }}
)

select distinct
  product_id      as id,
  title,
  category,
  brand,
  price,
  discount_percentage,
  discounted_price,
  rating,
  stock,
  stock_status
from base