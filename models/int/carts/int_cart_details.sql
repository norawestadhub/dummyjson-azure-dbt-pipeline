{{ config(materialized='view') }}

with
  carts as (
    select
      cart_id,
      user_id,
      cart_size
    from {{ ref('int_carts') }}
  ),

  users as (
    select
      user_id,
      full_name,
      age_group,
      city
    from {{ ref('int_users') }}
  ),

  products as (
    select
      product_id,
      title        as product_title,
      category,
      brand,
      discounted_price
    from {{ ref('int_products') }}
  ),

  cart_items as (
    select
      cart_id,
      product_id,
      quantity
    from {{ ref('stg_cart_items') }}
  )

select
  ci.cart_id,
  c.user_id,
  u.full_name,
  u.age_group,
  u.city,
  c.cart_size,
  ci.product_id,
  p.product_title,
  p.category,
  p.brand,
  p.discounted_price,
  ci.quantity,
  round(ci.quantity * p.discounted_price, 2) as item_total
from cart_items ci
left join carts   c on ci.cart_id    = c.cart_id
left join users   u on c.user_id     = u.user_id
left join products p on ci.product_id = p.product_id
