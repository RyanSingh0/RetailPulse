-- =====================================================================
-- 16_rfm_table.sql  ·  RetailPulse
-- Materialise the per-customer RFM table for Power BI (Page 2 visuals).
-- ---------------------------------------------------------------------
-- 12_rfm_segmentation.sql returns a SUMMARY; the dashboard needs the
-- per-customer rows so you can slice customers/revenue by segment and by
-- repeat-vs-one-time. Import this table and relate it to dim_customer
-- on customer_key (1:1).
-- =====================================================================

DROP TABLE IF EXISTS mart.rfm_segments;

CREATE TABLE mart.rfm_segments AS
WITH params AS (
    SELECT (MAX(order_purchase_ts)::DATE + 1) AS as_of_date
    FROM mart.fact_order_items
),
rfm_base AS (
    SELECT customer_key,
           (SELECT as_of_date FROM params) - MAX(order_purchase_ts)::DATE AS recency_days,
           COUNT(DISTINCT order_id)  AS frequency,
           SUM(gmv)                  AS monetary
    FROM mart.fact_order_items
    GROUP BY customer_key
),
rfm_scored AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
           -- Frequency is scored by VALUE (not NTILE): ~97% of customers
           -- ordered once, so NTILE on frequency would split identical
           -- values into arbitrary, engine-dependent buckets. Scoring by
           -- the actual order count is deterministic and reproducible.
           CASE WHEN frequency >= 3 THEN 5
                WHEN frequency  = 2 THEN 4
                ELSE 1 END                             AS f_score,
           NTILE(5) OVER (ORDER BY monetary    ASC ) AS m_score
    FROM rfm_base
)
SELECT customer_key,
       recency_days,
       frequency,
       ROUND(monetary, 2)                              AS monetary,
       r_score, f_score, m_score,
       -- Segments key on Recency x Monetary (the two dimensions with real
       -- spread); frequency is retained above as a repeat signal. This is
       -- deterministic and gives a balanced, defensible split.
       CASE
           WHEN r_score >= 4 AND m_score >= 4 THEN 'Champions'
           WHEN m_score >= 4 AND r_score <= 3 THEN 'Big Spenders (lapsing)'
           WHEN r_score >= 4 AND m_score <= 3 THEN 'Recent / Promising'
           WHEN r_score <= 2 AND m_score >= 3 THEN 'At Risk'
           WHEN r_score <= 2 AND m_score <= 2 THEN 'Hibernating'
           ELSE 'Needs Attention'
       END                                             AS segment,
       CASE WHEN frequency > 1 THEN 'Repeat' ELSE 'One-time' END AS customer_type
FROM rfm_scored;

-- Expect 94,983 rows. Segment check:
SELECT segment, COUNT(*) AS customers, ROUND(SUM(monetary),0) AS revenue
FROM mart.rfm_segments GROUP BY segment ORDER BY revenue DESC;
