{{ config(materialized='view') }}

with users as (
  select
    user_id,
    first_name,
    last_name,
    gender,
    age,
    email,
    city,
    company_name
  from {{ ref('stg_users') }}
)

select
  user_id,
  concat(first_name, ' ', last_name) as full_name,
  gender,
  age,
  email,
  city,
  company_name,
  case
    when age < 18                  then 'underage'
    when age between 18 and 30     then 'young_adult'
    when age between 31 and 60     then 'adult'
    else 'senior'
  end as age_group
from users
where email is not null
