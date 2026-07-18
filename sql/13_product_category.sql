-- =====================================================================
-- 13_product_category.sql  ·  RetailPulse
-- Product/category performance + the delivery-vs-review question.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Q1. Which categories drive revenue? (top-N with RANK())
-- ---------------------------------------------------------------------
-- Result: health_beauty (9.1%), watches_gifts (8.3%), bed_bath_table
-- (7.9%) lead; the long tail is fragmented across 70+ categories.
WITH category_rev AS (
    SELECT p.category,
           COUNT(DISTINCT f.order_id)  AS orders,
           SUM(f.gmv)                  AS revenue
    FROM mart.fact_order_items f
    JOIN mart.dim_product      p ON f.product_key = p.product_key
    GROUP BY p.category
)
SELECT RANK() OVER (ORDER BY revenue DESC)                       AS rank,
       category,
       orders,
       ROUND(revenue, 2)                                         AS revenue,
       ROUND(100.0 * revenue / SUM(revenue) OVER (), 1)          AS pct_of_total
FROM category_rev
ORDER BY revenue DESC
LIMIT 15;


-- ---------------------------------------------------------------------
-- Q2. THE business question: does faster delivery mean better reviews?
--     Join delivered orders to their review, bucket by delivery time,
--     and average the score per bucket.
-- ---------------------------------------------------------------------
-- Result: a clean monotonic relationship --
--     0-3 days  -> 4.46     15-21 days -> 4.12
--     4-7 days  -> 4.40     22+  days  -> 3.06
--     8-14 days -> 4.30
-- Delivery speed is the strongest controllable lever on satisfaction.
WITH delivered AS (
    SELECT DISTINCT f.order_id,
           f.delivery_days,
           r.review_score
    FROM mart.fact_order_items f
    JOIN stg.order_reviews     r ON f.order_id = r.order_id
    WHERE f.delivery_days IS NOT NULL
      AND f.delivery_days BETWEEN 0 AND 120        -- drop impossible outliers
)
SELECT CASE
           WHEN delivery_days <= 3  THEN '0-3 days'
           WHEN delivery_days <= 7  THEN '4-7 days'
           WHEN delivery_days <= 14 THEN '8-14 days'
           WHEN delivery_days <= 21 THEN '15-21 days'
           ELSE '22+ days'
       END                                                       AS delivery_bucket,
       COUNT(*)                                                  AS orders,
       ROUND(AVG(review_score), 2)                               AS avg_review,
       ROUND(100.0 * COUNT(*) FILTER (WHERE review_score >= 4)
             / COUNT(*), 1)                                      AS pct_positive
FROM delivered
GROUP BY delivery_bucket
ORDER BY MIN(delivery_days);


-- ---------------------------------------------------------------------
-- Q3. Same question, framed by the PROMISE: on-time vs late delivery.
-- ---------------------------------------------------------------------
-- Result: on-time/early -> 4.29 avg review; LATE -> 2.57.
-- Missing the promised date costs ~1.7 stars -- a churn/PR red flag.
WITH delivered AS (
    SELECT DISTINCT f.order_id, f.delivered_on_time, r.review_score
    FROM mart.fact_order_items f
    JOIN stg.order_reviews     r ON f.order_id = r.order_id
    WHERE f.delivered_on_time IS NOT NULL
)
SELECT CASE WHEN delivered_on_time THEN 'On time / early' ELSE 'Late' END AS delivery_status,
       COUNT(*)                     AS orders,
       ROUND(AVG(review_score), 2)  AS avg_review
FROM delivered
GROUP BY delivered_on_time
ORDER BY avg_review DESC;


-- ---------------------------------------------------------------------
-- Q4. Average review score by category (best & worst experiences).
-- ---------------------------------------------------------------------
WITH cat_reviews AS (
    SELECT p.category,
           AVG(r.review_score) AS avg_review,
           COUNT(*)            AS reviewed_items
    FROM mart.fact_order_items f
    JOIN mart.dim_product      p ON f.product_key = p.product_key
    JOIN stg.order_reviews     r ON f.order_id    = r.order_id
    GROUP BY p.category
    HAVING COUNT(*) >= 300                          -- ignore thin categories
)
SELECT category,
       reviewed_items,
       ROUND(avg_review, 2) AS avg_review
FROM cat_reviews
ORDER BY avg_review DESC;
