{{ config(materialized='view') }}

with raw_with_date as (
    select
        json_data,
        file_name,
        to_date(
          left(split_part(file_name, '_', 2), 10),
          'YYYY-MM-DD'
        ) as ingest_date
    from {{ ref('raw_users') }}
    where file_name is not null
),

latest as (
    select max(ingest_date) as last_date
    from raw_with_date
),

raw_data as (
    select json_data:users as users_array
    from raw_with_date r
    join latest       l
      on r.ingest_date = l.last_date
),

flattened as (
    select
      f.value:id::int                     as user_id,
      f.value:firstName::string           as first_name,
      f.value:lastName::string            as last_name,
      f.value:email::string               as email,
      f.value:age::int                    as age,
      f.value:gender::string              as gender,
      f.value:phone::string               as phone,
      f.value:address:city::string        as city,
      f.value:address:postalCode::string  as postal_code,
      f.value:company:name::string        as company_name
    from raw_data
      , lateral flatten(input => raw_data.users_array) f
)

select * from flattened
