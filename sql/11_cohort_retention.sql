-- =====================================================================
-- 11_cohort_retention.sql  ·  RetailPulse
-- Cohort retention: do customers come back after their first order?
-- ---------------------------------------------------------------------
-- The single most-asked analyst SQL pattern. Each customer is tagged
-- with a cohort = the month of their FIRST purchase; we then count how
-- many of that cohort transact again in each following month.
--
-- Honest finding up front: Olist is a near-pure ACQUISITION marketplace.
-- Only ~3.0% of customers ever place a second order, so the retention
-- grid collapses toward zero after month 0. Surfacing that clearly is
-- the analysis -- the heatmap's job is to make "they don't come back"
-- impossible to miss.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Q1. Headline: what share of customers ever order again?
-- ---------------------------------------------------------------------
-- Result: 92,096 of 94,983 customers are one-and-done -> repeat = 3.04%
WITH per_customer AS (
    SELECT customer_key, COUNT(DISTINCT order_id) AS orders
    FROM mart.fact_order_items
    GROUP BY customer_key
)
SELECT COUNT(*)                                               AS customers,
       COUNT(*) FILTER (WHERE orders > 1)                     AS repeat_customers,
       ROUND(100.0 * COUNT(*) FILTER (WHERE orders > 1)
             / COUNT(*), 2)                                   AS repeat_pct
FROM per_customer;


-- ---------------------------------------------------------------------
-- Q2. The cohort grid: % of each first-purchase cohort still active in
--     month N. Feeds the Power BI retention heatmap (matrix visual).
-- ---------------------------------------------------------------------
WITH customer_months AS (        -- distinct (customer, active month)
    SELECT DISTINCT customer_key, date_key AS active_month
    FROM mart.fact_order_items
),
first_purchase AS (              -- cohort = month of first order
    SELECT customer_key, MIN(active_month) AS cohort_month
    FROM customer_months
    GROUP BY customer_key
),
activity AS (                    -- months-since-cohort for every activity
    SELECT f.cohort_month,
           cm.customer_key,
           (EXTRACT(YEAR  FROM age(cm.active_month, f.cohort_month)) * 12
          + EXTRACT(MONTH FROM age(cm.active_month, f.cohort_month)))::INT
                                              AS period_index
    FROM customer_months cm
    JOIN first_purchase  f USING (customer_key)
),
cohort_size AS (
    SELECT cohort_month, COUNT(*) AS cohort_customers
    FROM first_purchase
    GROUP BY cohort_month
)
SELECT a.cohort_month,
       cs.cohort_customers,
       a.period_index,
       COUNT(DISTINCT a.customer_key)                                   AS active_customers,
       ROUND(100.0 * COUNT(DISTINCT a.customer_key)
             / cs.cohort_customers, 2)                                  AS retention_pct
FROM activity a
JOIN cohort_size cs USING (cohort_month)
WHERE a.period_index BETWEEN 0 AND 11
GROUP BY a.cohort_month, cs.cohort_customers, a.period_index
ORDER BY a.cohort_month, a.period_index;


-- ---------------------------------------------------------------------
-- Q3. Blended retention curve across all cohorts (one row per period).
-- ---------------------------------------------------------------------
-- Result: month 1 = 0.45% · month 2 = 0.29% · month 3 = 0.21% of buyers
-- -> the curve flatlines almost immediately. Growth must come from
-- acquisition + a great FIRST order, not loyalty (see delivery analysis).
WITH customer_months AS (
    SELECT DISTINCT customer_key, date_key AS active_month
    FROM mart.fact_order_items
),
first_purchase AS (
    SELECT customer_key, MIN(active_month) AS cohort_month
    FROM customer_months GROUP BY customer_key
),
activity AS (
    SELECT (EXTRACT(YEAR  FROM age(cm.active_month, f.cohort_month)) * 12
          + EXTRACT(MONTH FROM age(cm.active_month, f.cohort_month)))::INT AS period_index,
           cm.customer_key
    FROM customer_months cm JOIN first_purchase f USING (customer_key)
),
total AS (SELECT COUNT(*) AS all_customers FROM first_purchase)
SELECT period_index,
       COUNT(DISTINCT customer_key)                                AS active_customers,
       ROUND(100.0 * COUNT(DISTINCT customer_key)
             / (SELECT all_customers FROM total), 3)               AS pct_of_base
FROM activity
WHERE period_index BETWEEN 0 AND 11
GROUP BY period_index
ORDER BY period_index;
