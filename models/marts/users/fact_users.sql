{{ config(materialized='table') }}

with base as (
  select
    user_id,
    full_name,
    age_group,
    gender,
    city,
    email
  from {{ ref('int_users') }}
)

select
  user_id         as id,
  full_name,
  age_group,
  gender,
  city,
  email
from base