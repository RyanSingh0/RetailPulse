-- =====================================================================
-- 14_geography.sql  ·  RetailPulse
-- Where are the customers and the money? Feeds the Brazil map page.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Q1. Revenue, orders and customers by state (+ share of total).
-- ---------------------------------------------------------------------
-- Result: Sao Paulo (SP) alone is 37.4% of revenue; SP+RJ+MG (the
-- southeast) is the clear core. Heavy geographic concentration =
-- both a strength (dense logistics) and a risk (over-reliance on SP).
WITH by_state AS (
    SELECT c.state,
           COUNT(DISTINCT f.order_id)        AS orders,
           COUNT(DISTINCT f.customer_key)    AS customers,
           SUM(f.gmv)                        AS revenue
    FROM mart.fact_order_items f
    JOIN mart.dim_customer     c ON f.customer_key = c.customer_key
    GROUP BY c.state
)
SELECT state,
       orders,
       customers,
       ROUND(revenue, 2)                                       AS revenue,
       ROUND(100.0 * revenue / SUM(revenue) OVER (), 1)        AS pct_of_revenue,
       ROUND(revenue / orders, 2)                              AS aov,
       RANK() OVER (ORDER BY revenue DESC)                     AS revenue_rank
FROM by_state
ORDER BY revenue DESC;


-- ---------------------------------------------------------------------
-- Q2. Regional roll-up (Brazil's 5 macro-regions) for a cleaner story.
-- ---------------------------------------------------------------------
WITH region_map AS (
    SELECT f.gmv, f.order_id, f.customer_key,
           CASE
               WHEN c.state IN ('SP','RJ','MG','ES')                THEN 'Southeast'
               WHEN c.state IN ('RS','PR','SC')                     THEN 'South'
               WHEN c.state IN ('BA','PE','CE','MA','PB','RN','AL','SE','PI') THEN 'Northeast'
               WHEN c.state IN ('GO','DF','MT','MS')                THEN 'Center-West'
               WHEN c.state IN ('AM','PA','RO','TO','AC','AP','RR') THEN 'North'
               ELSE 'Other'
           END AS region
    FROM mart.fact_order_items f
    JOIN mart.dim_customer     c ON f.customer_key = c.customer_key
)
SELECT region,
       COUNT(DISTINCT order_id)                                AS orders,
       COUNT(DISTINCT customer_key)                            AS customers,
       ROUND(SUM(gmv), 2)                                      AS revenue,
       ROUND(100.0 * SUM(gmv) / SUM(SUM(gmv)) OVER (), 1)      AS pct_of_revenue,
       ROUND(SUM(gmv) / COUNT(DISTINCT order_id), 2)           AS aov
FROM region_map
GROUP BY region
ORDER BY revenue DESC;


-- ---------------------------------------------------------------------
-- Q3. Top 10 cities by revenue (drill-down under the map).
-- ---------------------------------------------------------------------
SELECT c.city,
       c.state,
       COUNT(DISTINCT f.order_id)        AS orders,
       ROUND(SUM(f.gmv), 2)              AS revenue
FROM mart.fact_order_items f
JOIN mart.dim_customer     c ON f.customer_key = c.customer_key
GROUP BY c.city, c.state
ORDER BY revenue DESC
LIMIT 10;
