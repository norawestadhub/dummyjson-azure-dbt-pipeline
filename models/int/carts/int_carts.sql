Here’s your **`int_carts.sql`** model with all comments translated to English:

```sql
{{ config(materialized='view') }}

-- 1) Aggregate the number of product lines and total quantity per cart
with aggregated_items as (
  select
    cart_id,
    count(*)                as total_products,
    sum(quantity)           as total_quantity
  from {{ ref('stg_cart_items') }}
  group by cart_id
),

-- 2) Join staging carts with the aggregated metrics
carts as (
  select
    sc.cart_id,
    sc.user_id,
    sc.total,
    sc.discounted_total,
    coalesce(ai.total_products,  0) as total_products,
    coalesce(ai.total_quantity,  0) as total_quantity
  from {{ ref('stg_carts') }}       sc
  left join aggregated_items       ai
    on sc.cart_id = ai.cart_id
)

-- 3) Final select: average price per item + cart size category
select
  cart_id,
  user_id,
  total,
  discounted_total,
  total_products,
  total_quantity,
  round(discounted_total / nullif(total_quantity, 0), 2) as avg_price_per_item,
  case
    when total_quantity > 10              then 'bulk_cart'
    when total_quantity between 5 and 10   then 'medium_cart'
    else 'small_cart'
  end as cart_size
from carts
```
