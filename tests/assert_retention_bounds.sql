-- Retention % should be between 0 and 100
select *
from {{ ref('fct_user_retention') }}
where retention_pct < 0 or retention_pct > 100
