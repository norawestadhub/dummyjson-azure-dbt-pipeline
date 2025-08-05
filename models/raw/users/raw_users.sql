select
  json_data,
  file_name
from {{ source('dummyjson', 'users_raw') }}
