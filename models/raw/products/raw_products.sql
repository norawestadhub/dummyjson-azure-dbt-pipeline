SELECT * 

FROM {{ source('dummyjson', 'products_raw') }}
