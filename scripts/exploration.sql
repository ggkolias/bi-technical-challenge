-- =============================================================================
-- Data Exploration (SQL)
-- Run in pgAdmin or psql against bi_challenge database
-- Schema: bi_challenge
-- =============================================================================

-- 1. Row counts
-- -------------
SELECT 'backend_events' AS table_name, COUNT(*) AS row_count FROM bi_challenge.backend_events
UNION ALL
SELECT 'hubspot_deals', COUNT(*) FROM bi_challenge.hubspot_deals
UNION ALL
SELECT 'hubspot_companies', COUNT(*) FROM bi_challenge.hubspot_companies
UNION ALL
SELECT 'hubspot_contacts', COUNT(*) FROM bi_challenge.hubspot_contacts;


-- 2. Nulls and data quality
-- ------------------------
SELECT 
    COUNT(*) AS total,
    COUNT(event_id) AS event_id_not_null,
    COUNT(user_id) AS user_id_not_null,
    COUNT(organization_id) AS org_id_not_null
FROM bi_challenge.backend_events;

SELECT 
    COUNT(*) AS total,
    COUNT(CASE WHEN amount IS NULL OR amount <= 0 THEN 1 END) AS amount_issues,
    COUNT(CASE WHEN close_date IS NULL AND LOWER(TRIM(is_closed_won::text)) = 'true' THEN 1 END) AS won_no_close_date
FROM bi_challenge.hubspot_deals;


-- 3. Date ranges
-- --------------
SELECT 
    MIN(event_timestamp) AS first_event,
    MAX(event_timestamp) AS last_event
FROM bi_challenge.backend_events;

SELECT 
    MIN(create_date) AS first_deal_created,
    MAX(create_date) AS last_deal_created,
    MIN(close_date) AS first_deal_closed,
    MAX(close_date) AS last_deal_closed
FROM bi_challenge.hubspot_deals;


-- 4. Event types (backend)
-- -----------------------
SELECT event_name, COUNT(*) AS event_count
FROM bi_challenge.backend_events
GROUP BY event_name
ORDER BY event_count DESC;


-- 5. Deal pipeline (HubSpot)
-- --------------------------
SELECT 
    LOWER(TRIM(is_closed_won::text)) AS is_closed_won,
    COUNT(*) AS deal_count,
    SUM(amount) AS total_amount
FROM bi_challenge.hubspot_deals
GROUP BY LOWER(TRIM(is_closed_won::text));


-- 6. Currency mix
-- --------------
SELECT currency, COUNT(*) AS deals, SUM(amount) AS total
FROM bi_challenge.hubspot_deals
GROUP BY currency;


-- 7. Referential integrity
-- ------------------------
-- Deals referencing non-existent companies
SELECT d.deal_id, d.hubspot_company_id
FROM bi_challenge.hubspot_deals d
LEFT JOIN bi_challenge.hubspot_companies c ON d.hubspot_company_id = c.company_id
WHERE c.company_id IS NULL;
-- (Expect 0 rows)


-- 8. Users per organization (backend)
-- ----------------------------------
SELECT 
    COUNT(DISTINCT organization_id) AS orgs,
    COUNT(DISTINCT user_id) AS users
FROM bi_challenge.backend_events;


-- 9. Event volume over time (monthly)
-- ------------------------------------
SELECT 
    DATE_TRUNC('month', event_timestamp::timestamp)::date AS month,
    COUNT(*) AS event_count
FROM bi_challenge.backend_events
GROUP BY DATE_TRUNC('month', event_timestamp::timestamp)
ORDER BY month;


-- 10. Industry / country of customers
-- -----------------------------------
SELECT 
    c.industry,
    c.country,
    COUNT(DISTINCT d.hubspot_company_id) AS customers,
    SUM(d.amount) AS revenue
FROM bi_challenge.hubspot_deals d
JOIN bi_challenge.hubspot_companies c ON d.hubspot_company_id = c.company_id
WHERE LOWER(TRIM(d.is_closed_won::text)) = 'true'
GROUP BY c.industry, c.country
ORDER BY revenue DESC;
