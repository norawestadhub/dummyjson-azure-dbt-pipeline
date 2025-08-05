SELECT * 

FROM {{ source('dummyjson', 'carts_raw') }}