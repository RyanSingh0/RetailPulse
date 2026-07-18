-- =====================================================================
-- 15_cohort_table.sql  ·  RetailPulse
-- Materialise the cohort-retention grid as a table for Power BI.
-- ---------------------------------------------------------------------
-- The Power BI matrix on the Customers page needs cohort_month (rows),
-- period_index (columns) and retention_pct (values). Those are the
-- OUTPUT of the cohort query, not columns in the star schema -- so we
-- build them once here and import this table into the model.
--   Rows    = cohort_month
--   Columns = period_index
--   Values  = retention_pct   (conditional-format for the heatmap)
-- =====================================================================

DROP TABLE IF EXISTS mart.cohort_retention;

CREATE TABLE mart.cohort_retention AS
WITH customer_months AS (
    SELECT DISTINCT customer_key, date_key AS active_month
    FROM mart.fact_order_items
),
first_purchase AS (
    SELECT customer_key, MIN(active_month) AS cohort_month
    FROM customer_months
    GROUP BY customer_key
),
activity AS (
    SELECT f.cohort_month,
           cm.customer_key,
           (EXTRACT(YEAR  FROM age(cm.active_month, f.cohort_month)) * 12
          + EXTRACT(MONTH FROM age(cm.active_month, f.cohort_month)))::INT AS period_index
    FROM customer_months cm
    JOIN first_purchase  f USING (customer_key)
),
cohort_size AS (
    SELECT cohort_month, COUNT(*) AS cohort_customers
    FROM first_purchase
    GROUP BY cohort_month
)
SELECT a.cohort_month,
       to_char(a.cohort_month, 'YYYY-MM')                       AS cohort_label,
       cs.cohort_customers,
       a.period_index,
       COUNT(DISTINCT a.customer_key)                           AS active_customers,
       ROUND(100.0 * COUNT(DISTINCT a.customer_key)
             / cs.cohort_customers, 2)                          AS retention_pct
FROM activity a
JOIN cohort_size cs USING (cohort_month)
WHERE a.period_index BETWEEN 0 AND 11
GROUP BY a.cohort_month, cs.cohort_customers, a.period_index
ORDER BY a.cohort_month, a.period_index;

-- Expect ~181 rows across 23 cohorts; period_index 0 is always 100%.
SELECT COUNT(*) AS rows,
       COUNT(DISTINCT cohort_month) AS cohorts,
       MAX(period_index) AS max_period
FROM mart.cohort_retention;
