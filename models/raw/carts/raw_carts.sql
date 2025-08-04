select
  json_data,
  file_name
from {{ source('dummyjson', 'carts_raw') }}