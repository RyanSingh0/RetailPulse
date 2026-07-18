-- =====================================================================
-- 10_kpis.sql  ·  RetailPulse
-- Executive KPIs + growth trend (window functions).
-- =====================================================================

-- ---------------------------------------------------------------------
-- Q1. What is the business worth at a glance?
--     Total revenue, orders, unique customers, average order value.
-- ---------------------------------------------------------------------
-- Result: 98,199 orders · 94,983 customers · R$15.74M GMV · AOV R$160.24
SELECT COUNT(DISTINCT order_id)                              AS total_orders,
       COUNT(DISTINCT customer_key)                         AS total_customers,
       ROUND(SUM(gmv), 2)                                   AS total_revenue,
       ROUND(SUM(gmv) / COUNT(DISTINCT order_id), 2)        AS avg_order_value
FROM mart.fact_order_items;


-- ---------------------------------------------------------------------
-- Q2. How fast is revenue growing month over month?
--     LAG() reads the previous month on an ordered monthly series so we
--     can compute MoM % without a self-join, plus a running cumulative
--     total with SUM() OVER (ORDER BY month).
-- ---------------------------------------------------------------------
-- Takeaway: growth is steep through 2017 then plateaus ~R$1.0-1.15M/mo
-- in mid-2018 -- the business matured from "hyper-growth" to "scale".
WITH monthly AS (
    SELECT date_key                              AS month,
           SUM(gmv)                              AS revenue,
           COUNT(DISTINCT order_id)              AS orders
    FROM mart.fact_order_items
    GROUP BY date_key
)
SELECT month,
       ROUND(revenue, 2)                                              AS revenue,
       orders,
       ROUND(revenue - LAG(revenue) OVER (ORDER BY month), 2)         AS mom_change,
       ROUND( 100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
              / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 1)     AS mom_growth_pct,
       ROUND(SUM(revenue) OVER (ORDER BY month), 2)                   AS cumulative_revenue,
       ROUND(AVG(revenue) OVER (ORDER BY month
              ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2)          AS rolling_3mo_avg
FROM monthly
ORDER BY month;


-- ---------------------------------------------------------------------
-- Q3. Average order value by month -- is each order getting bigger?
-- ---------------------------------------------------------------------
-- Takeaway: AOV is remarkably flat (~R$155-165), so revenue growth is
-- driven by ORDER VOLUME, not basket size -- an acquisition business.
SELECT date_key                                       AS month,
       COUNT(DISTINCT order_id)                       AS orders,
       ROUND(SUM(gmv) / COUNT(DISTINCT order_id), 2)  AS aov
FROM mart.fact_order_items
GROUP BY date_key
ORDER BY month;
