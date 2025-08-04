select
  json_data,
  file_name
from {{ source('dummyjson', 'products_raw') }}
