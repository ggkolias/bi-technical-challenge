{{
    config(
        materialized='table'
    )
}}
/*
    Q2: What is our Average Contract Value (ACV)?
    
    ACV = Total contract value / Number of customers
    Per customer = sum of all closed-won deal amounts for that company.
*/
with customer_contract_value as (
    select
        hubspot_company_id,
        sum(amount) as total_contract_value
    from {{ ref('stg_hubspot_deals') }}
    where is_closed_won = true
    group by hubspot_company_id
),

acv_summary as (
    select
        count(*) as customer_count,
        sum(total_contract_value) as total_revenue,
        avg(total_contract_value) as acv
    from customer_contract_value
)

select
    customer_count,
    total_revenue,
    round(acv, 2) as average_contract_value
from acv_summary
