{{ config(
    materialized = 'table',
    alias        = 'fact_carts_products'
) }}

with cart_items as (

  select
    cart_id,
    user_id,
    product_id,
    quantity
  from {{ ref('int_cart_details') }}

),

items_with_total as (

  select
    ci.cart_id,
    ci.user_id,
    ci.product_id,

    -- bring in discounted_price if it exists, otherwise null
    dp.discounted_price,

    ci.quantity,

    -- calculate item_total even if discounted_price is null
    round(ci.quantity * coalesce(dp.discounted_price, 0), 2) as item_total

  from cart_items as ci

  left join {{ ref('dim_products') }} as dp
    on ci.product_id = dp.id

)

select distinct
  *
from items_with_total
