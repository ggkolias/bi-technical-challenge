# BI Technical Challenge — Solution

This document describes my approach, assumptions, and answers for the BI Technical Challenge.

---

## Setup

### Prerequisites

- PostgreSQL (local or remote)
- Python 3.9+

### Database connection (profiles.yml)

dbt needs a connection profile to reach PostgreSQL. Copy the example and adjust for your environment:

```bash
cp profiles.yml.example profiles.yml
```

Edit `profiles.yml` and set:
- **user** — Your Postgres username (e.g. your system username on macOS, or `postgres`)
- **password** — Your Postgres password (or leave empty if using trust auth)
- **host** — `localhost` by default; change if Postgres runs elsewhere
- **dbname** — `fln` (must match the database you create)
- **schema** — `bi_challenge` (schema where dbt creates tables)

### Run the project

```bash
# 1. Create database
createdb fln

# 2. Create virtual environment and install dbt
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 3. Configure connection (see above)
cp profiles.yml.example profiles.yml
# Edit profiles.yml with your credentials

# 4. Load data and run models
dbt seed
dbt run

# 5. Run tests
dbt test
```

### Project structure

```
models/
├── marts/            # Mart models (tables) — answers to business questions
├── staging/          # Staging models (views) — raw data with basic cleaning
scripts/
├── exploration.sql   # Ad-hoc SQL for data exploration
tests/                # dbt tests (schema + singular)
```

---

## Answers

### Question 1: How many customers do we have today?

**Answer:** 26 customers.

```sql
SELECT COUNT(*) FROM bi_challenge.fct_customers;
```

**Assumptions:**
- A **customer** = a company with at least one closed-won deal.
- "Today" = the latest date in the data (effectively, we include all closed-won deals; no cutoff date applied).
- Deals with `close_date` null are excluded even if `is_closed_won` is true.

---

### Question 2: What is our Average Contract Value (ACV)?

**Answer:**

| customer_count | total_revenue | average_contract_value |
|----------------|---------------|------------------------|
| 26             | 402,000       | €15,461.54             |

```sql
SELECT * FROM bi_challenge.fct_acv;
```

**Assumptions:**
- ACV = total contract value / number of customers (not per deal).
- For companies with multiple closed-won deals, we sum all deal amounts.
- All amounts are in EUR. In case other currencies will show up, we need to tackle the issue earlier and change the currencies to the main currency of the company.

---

### Question 3: What is the retention of our users?

**Answer:** Retention by join month and months since signup. The result set is detailed — run the query for the full output.

```sql
SELECT * FROM bi_challenge.fct_user_retention ORDER BY join_month, months_since_signup;
```

**Assumptions:**
- **Retention** = share of users who had activity in a given month among those whose first activity was in an earlier month.
- **Join month** = month of first event (excluding `TokenGenerated`).
- **Activity** = any event except `TokenGenerated` (login/session refresh excluded).
- Retention is calculated at user level.

---

### Bonus: Deal velocity

Additional insight: **average days to close a won deal**, by deal type.

**Answer:**

| deal_type          | deal_count | avg_days_to_close | min_days_to_close | max_days_to_close | median_days_to_close |
|--------------------|------------|-------------------|-------------------|-------------------|---------------------|
| all                | 31         | 89.1              | 16                | 150               | 98                  |
| existing_business  | 5          | 24.4              | 16                | 38                | 24                  |
| newbusiness        | 26         | 101.6             | 32                | 150               | 105.5               |

```sql
SELECT * FROM bi_challenge.fct_deal_velocity;
```

**Insight:** Expansion deals (`existing_business`) close much faster (avg 24 days) than new business deals (avg 102 days).

---

## Assumptions log

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Customer = company with closed-won deal | Standard revenue definition; aligns with CRM. |
| 2 | No cutoff date for "today" | Dataset is a snapshot; all closed-won deals taken as current customers. |
| 3 | Exclude TokenGenerated from retention | Session refresh is not meaningful product usage. |
| 4 | Join month = first activity month | No explicit signup event; first event used as proxy. |
| 5 | ACV per customer, not per deal | Standard ACV definition; multi-deal companies get sum of amounts. |
| 6 | Backend and HubSpot not linked | Different ID schemes (UUID vs integer); no direct join attempted. |
| 7 | hubspot_org.csv = hubspot_companies.csv | Challenge mentions hubspot_org.csv; repo contains hubspot_companies.csv. Assumed same file (company/org records). |

---

## Data quality notes

- **Referential integrity:** All deals and contacts reference valid companies (tested via `relationships`).
- **Backend events:** Date range 2024-07-03 to 2026-02-08 (event_timestamp), so the range seems reasonable and does not include future dates. No nulls in key fields, no duplicates on event_id.
- **HubSpot deals:** create_date range 2024-05-06 to 2026-01-15; close_date range 2024-09-17 to 2026-02-09. Single currency (EUR), no duplicates on deal_id.
