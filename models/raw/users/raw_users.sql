SELECT * 

FROM {{ source('dummyjson', 'users_raw') }}