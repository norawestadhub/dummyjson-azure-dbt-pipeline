with carts as (
    select
        cart_id,
        user_id,
        total,
        discounted_total,
        total_products,
        total_quantity
    from {{ ref('stg_carts') }}
)

select
    cart_id,
    user_id,
    total,
    discounted_total,
    total_products,
    total_quantity,
    round(discounted_total / nullif(total_quantity, 0), 2) as avg_price_per_item,
    case
        when total_quantity > 10 then 'bulk_cart'
        when total_quantity between 5 and 10 then 'medium_cart'
        else 'small_cart'
    end as cart_size
from carts
