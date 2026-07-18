-- =====================================================================
-- 12_rfm_segmentation.sql  ·  RetailPulse
-- RFM customer segmentation with NTILE() quintiles.
-- ---------------------------------------------------------------------
-- For every customer compute:
--   Recency   = days since their most recent order (smaller = better)
--   Frequency = number of distinct orders
--   Monetary  = total GMV
-- Score each into 1-5 quintiles with NTILE(5), then bucket the scores
-- into named segments a marketer can act on.
--
-- Analyst note: because ~97% of Olist customers order exactly once, the
-- Frequency dimension is nearly constant -- segmentation is driven mainly
-- by Recency and Monetary. We call that out rather than pretend the F
-- axis is doing work it isn't; the value is identifying the small, high-
-- value "Champions" tail and the large "At Risk" lapsed base.
-- =====================================================================

-- Analysis date = day after the last order in the data (a fixed "today")
-- so Recency is reproducible.
WITH params AS (
    SELECT (MAX(order_purchase_ts)::DATE + 1) AS as_of_date
    FROM mart.fact_order_items
),
rfm_base AS (
    SELECT customer_key,
           (SELECT as_of_date FROM params)
               - MAX(order_purchase_ts)::DATE          AS recency_days,
           COUNT(DISTINCT order_id)                    AS frequency,
           SUM(gmv)                                    AS monetary
    FROM mart.fact_order_items
    GROUP BY customer_key
),
rfm_scored AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,  -- recent -> 5
           -- Frequency scored by VALUE, not NTILE: ~97% of customers order
           -- once, so NTILE would bucket identical values arbitrarily
           -- (and differently per engine). By-value scoring is stable.
           CASE WHEN frequency >= 3 THEN 5
                WHEN frequency  = 2 THEN 4
                ELSE 1 END                            AS f_score,
           NTILE(5) OVER (ORDER BY monetary    ASC ) AS m_score
    FROM rfm_base
),
segmented AS (
    -- Segments key on Recency x Monetary (the dimensions with real spread);
    -- frequency is kept as a repeat signal. Deterministic + balanced.
    SELECT *,
           CASE
               WHEN r_score >= 4 AND m_score >= 4 THEN 'Champions'
               WHEN m_score >= 4 AND r_score <= 3 THEN 'Big Spenders (lapsing)'
               WHEN r_score >= 4 AND m_score <= 3 THEN 'Recent / Promising'
               WHEN r_score <= 2 AND m_score >= 3 THEN 'At Risk'
               WHEN r_score <= 2 AND m_score <= 2 THEN 'Hibernating'
               ELSE 'Needs Attention'
           END AS segment
    FROM rfm_scored
)
-- Segment summary -> the bar/donut on the Customers page.
-- Result highlight: "Big Spenders (lapsing)" hold ~43% of revenue from
-- 23% of customers; "Champions" (recent + high spend) are ~16%.
SELECT segment,
       COUNT(*)                                              AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS pct_customers,
       ROUND(SUM(monetary), 2)                               AS revenue,
       ROUND(100.0 * SUM(monetary)
             / SUM(SUM(monetary)) OVER (), 1)                AS pct_revenue,
       ROUND(AVG(monetary), 2)                               AS avg_spend,
       ROUND(AVG(recency_days), 0)                           AS avg_recency_days
FROM segmented
GROUP BY segment
ORDER BY revenue DESC;

-- To export the per-customer table for Power BI, replace the final
-- SELECT above with:  SELECT customer_key, recency_days, frequency,
-- monetary, r_score, f_score, m_score, segment FROM segmented;
