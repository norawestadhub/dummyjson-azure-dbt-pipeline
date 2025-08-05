SELECT * 

FROM {{ source('dummyjson', 'imported_carts') }}