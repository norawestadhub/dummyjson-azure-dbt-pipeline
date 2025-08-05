SELECT * 

FROM {{ source('dummyjson', 'imported_products') }}