{{
    config(
        materialized='view'
    )
}}

select
    contact_id,
    first_name,
    last_name,
    email,
    job_title,
    hubspot_company_id,
    lifecycle_stage,
    cast(create_date as date) as create_date
from {{ ref('hubspot_contacts') }}
