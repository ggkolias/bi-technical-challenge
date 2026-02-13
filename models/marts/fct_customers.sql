{{
    config(
        materialized='table'
    )
}}
/*
    Q1: How many customers do we have today?
    
    Definition: A customer = a company with at least one closed-won deal.
    "Today" = latest date in the data (we use max close_date).
*/
with closed_won_deals as (
    select distinct hubspot_company_id
    from {{ ref('stg_hubspot_deals') }}
    where is_closed_won = true
      and close_date is not null
)

select
    c.company_id,
    c.company_name,
    c.domain,
    c.industry,
    c.country
from {{ ref('stg_hubspot_companies') }} c
inner join closed_won_deals d on c.company_id = d.hubspot_company_id
