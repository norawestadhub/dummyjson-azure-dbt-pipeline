SELECT * 

FROM {{ source('dummyjson', 'imported_users') }}