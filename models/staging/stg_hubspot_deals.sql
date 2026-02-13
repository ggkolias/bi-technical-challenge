{{
    config(
        materialized='view'
    )
}}

select
    deal_id,
    deal_name,
    pipeline,
    lower(trim(is_closed::varchar)) = 'true' as is_closed,
    lower(trim(is_closed_won::varchar)) = 'true' as is_closed_won,
    amount,
    cast(close_date as date) as close_date,
    cast(create_date as date) as create_date,
    hubspot_company_id,
    deal_type,
    currency
from {{ ref('hubspot_deals') }}
