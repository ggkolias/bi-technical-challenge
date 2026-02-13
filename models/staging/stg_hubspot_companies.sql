{{
    config(
        materialized='view'
    )
}}

select
    company_id,
    company_name,
    domain,
    industry,
    country,
    number_of_employees,
    cast(create_date as date) as create_date
from {{ ref('hubspot_companies') }}
