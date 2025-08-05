{{ config(materialized='table') }}

with cart_summary as (
  select
    cart_id,
    user_id,
    total,
    discounted_total,
    total_products,
    total_quantity,
    avg_price_per_item,
    cart_size
  from {{ ref('int_carts') }}
),

cart_details as (
  select
    cart_id,
    sum(item_total) as order_total,
    count(distinct product_id) as distinct_products
  from {{ ref('int_cart_details') }}
  group by cart_id
)

select
  cs.cart_id,
  u.full_name    as user_name,
  cs.user_id,
  cs.total       as original_cart_value,
  cs.discounted_total,
  cd.order_total as actual_spent,
  cs.total_products,
  cs.total_quantity,
  cd.distinct_products,
  cs.avg_price_per_item,
  cs.cart_size
from cart_summary cs
left join {{ ref('dim_users') }} u on cs.user_id = u.id
left join cart_details cd on cs.cart_id = cd.cart_id