-- =====================================================================
-- UPDATES.sql  ·  RetailPulse
-- Incremental patches for a database that was built BEFORE the fact table
-- gained `review_score` and dim_customer gained `region`. Run this once
-- (in psql, connected to retailpulse), then Refresh in Power BI.
-- A fresh run of 03_star_schema.sql already includes both -- this file is
-- only for not rebuilding everything.
-- =====================================================================

-- 1. Add review_score to the fact (for Page 3 review visuals) ----------
ALTER TABLE mart.fact_order_items ADD COLUMN IF NOT EXISTS review_score INT;

UPDATE mart.fact_order_items f
SET    review_score = r.review_score
FROM   stg.order_reviews r
WHERE  f.order_id = r.order_id;

-- 2. Add region to dim_customer (for Page 4 regional matrix) -----------
ALTER TABLE mart.dim_customer ADD COLUMN IF NOT EXISTS region TEXT;

UPDATE mart.dim_customer
SET region = CASE
        WHEN state IN ('SP','RJ','MG','ES')                THEN 'Southeast'
        WHEN state IN ('RS','PR','SC')                     THEN 'South'
        WHEN state IN ('BA','PE','CE','MA','PB','RN','AL','SE','PI') THEN 'Northeast'
        WHEN state IN ('GO','DF','MT','MS')                THEN 'Center-West'
        WHEN state IN ('AM','PA','RO','TO','AC','AP','RR') THEN 'North'
        ELSE 'Other'
    END;

-- 3. Build the tables the dashboard pages need ------------------------
-- (16_rfm_table.sql now uses the deterministic R x M segmentation --
--  re-run it to replace any earlier, unstable NTILE-frequency version.)
\i C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/sql/15_cohort_table.sql
\i C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/sql/16_rfm_table.sql
\i C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/sql/17_dim_state.sql

-- Verify
SELECT 'fact has review_score' AS check,
       COUNT(*) FILTER (WHERE review_score IS NOT NULL) AS non_null
FROM mart.fact_order_items
UNION ALL
SELECT 'customers with region', COUNT(*) FROM mart.dim_customer WHERE region <> 'Other';
