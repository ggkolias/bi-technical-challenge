-- ACV and customer count should be positive
-- Fails if any row has non-positive values
select
    customer_count,
    total_revenue,
    average_contract_value
from {{ ref('fct_acv') }}
where customer_count <= 0
   or average_contract_value <= 0
