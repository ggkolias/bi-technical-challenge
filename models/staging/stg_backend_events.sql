{{
    config(
        materialized='view'
    )
}}

select
    event_id,
    event_name,
    cast(event_timestamp as timestamp) as event_timestamp,
    user_id,
    organization_id,
    event_properties
from {{ ref('backend_events') }}
