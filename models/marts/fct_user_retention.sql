{{
    config(
        materialized='table'
    )
}}
/*
    Q3: What is the retention of our users?
    
    Retention by join month: For users who had their first activity in each month,
    what % had activity in subsequent months?
    
    Activity = any event EXCEPT TokenGenerated (session refresh, not real usage).
*/
with activity_events as (
    select
        user_id,
        organization_id,
        event_timestamp,
        event_name
    from {{ ref('stg_backend_events') }}
    where event_name != 'TokenGenerated'
),

user_first_activity as (
    select
        user_id,
        min(date_trunc('month', event_timestamp))::date as join_month
    from activity_events
    group by user_id
),

user_monthly_activity as (
    select distinct
        user_id,
        date_trunc('month', event_timestamp)::date as activity_month
    from activity_events
),

join_month_retention as (
    select
        ufa.join_month,
        ufa.user_id,
        uma.activity_month,
        -- Month index: 0 = join month, 1 = month 1, 2 = month 2, etc.
        (extract(year from uma.activity_month)::int - extract(year from ufa.join_month)::int) * 12
        + (extract(month from uma.activity_month)::int - extract(month from ufa.join_month)::int) as months_since_signup
    from user_first_activity ufa
    inner join user_monthly_activity uma
        on ufa.user_id = uma.user_id
        and uma.activity_month >= ufa.join_month
),

retention_summary as (
    select
        join_month,
        months_since_signup,
        count(distinct user_id) as retained_users
    from join_month_retention
    group by join_month, months_since_signup
),

join_month_sizes as (
    select
        join_month,
        count(distinct user_id) as join_month_size
    from user_first_activity
    group by join_month
),

retention_pct as (
    select
        r.join_month,
        r.months_since_signup,
        r.retained_users,
        c.join_month_size,
        round(100.0 * r.retained_users / c.join_month_size, 2) as retention_pct
    from retention_summary r
    inner join join_month_sizes c on r.join_month = c.join_month
)

select * from retention_pct
order by join_month, months_since_signup
