{{
    config(
        materialized='table'
    )
}}
/*
    Bonus: Deal velocity (sales cycle length)
    
    - Summary row (deal_type = 'all'): overall stats
    - Breakdown by deal_type: newbusiness vs existing_business
*/
with won_deals as (
    select
        deal_id,
        deal_type,
        (close_date - create_date) as days_to_close
    from {{ ref('stg_hubspot_deals') }}
    where is_closed_won = true
      and close_date is not null
      and create_date is not null
),

-- Overall summary
overall as (
    select
        'all' as deal_type,
        count(*) as deal_count,
        round(avg(days_to_close), 1) as avg_days_to_close,
        min(days_to_close) as min_days_to_close,
        max(days_to_close) as max_days_to_close,
        percentile_cont(0.5) within group (order by days_to_close) as median_days_to_close
    from won_deals
),

-- By deal type
by_type as (
    select
        coalesce(deal_type, 'unknown') as deal_type,
        count(*) as deal_count,
        round(avg(days_to_close), 1) as avg_days_to_close,
        min(days_to_close) as min_days_to_close,
        max(days_to_close) as max_days_to_close,
        percentile_cont(0.5) within group (order by days_to_close) as median_days_to_close
    from won_deals
    group by deal_type
)

select * from overall
union all
select * from by_type
order by deal_type
