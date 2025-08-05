with products as (
    select
        product_id,
        title,
        description,
        price,
        discount_percentage,
        rating,
        stock,
        brand,
        category
    from {{ ref('stg_products') }}
)

select
    product_id,
    title,
    category,
    brand,
    price,
    discount_percentage,
    price * (1 - discount_percentage / 100.0) as discounted_price,
    rating,
    stock,
    case
        when stock = 0 then 'out_of_stock'
        when stock < 10 then 'low_stock'
        else 'in_stock'
    end as stock_status
from products
where rating >= 3.0
