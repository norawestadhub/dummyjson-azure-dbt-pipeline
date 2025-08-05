with raw_carts as (
    select * from {{ ref('raw_carts') }}
),

flattened_items as (
    select
        cart_id,
        user_id,
        item.value:productId::int as product_id,
        item.value:quantity::int as quantity
    from raw_carts,
    lateral flatten(input => raw_carts.products) as item
)

select
    cart_id,
    user_id,
    product_id,
    quantity
from flattened_items
