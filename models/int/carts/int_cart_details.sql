with carts as (
    select * from {{ ref('int_carts') }}
),

users as (
    select * from {{ ref('int_users') }}
),

products as (
    select * from {{ ref('int_products') }}
),

cart_items as (
    select
        cart_id,
        product_id,
        quantity
    from {{ ref('stg_cart_items') }} -- antar at du har en egen modell for dette
)

select
    carts.cart_id,
    users.user_id,
    users.full_name,
    users.age_group,
    users.city,
    carts.cart_size,
    cart_items.product_id,
    products.title as product_title,
    products.category,
    products.brand,
    products.discounted_price,
    cart_items.quantity,
    round(cart_items.quantity * products.discounted_price, 2) as item_total
from cart_items
left join carts on cart_items.cart_id = carts.cart_id
left join users on carts.user_id = users.user_id
left join products on cart_items.product_id = products.product_id
