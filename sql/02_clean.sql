-- =====================================================================
-- 02_clean.sql  ·  RetailPulse
-- Turn permissive `raw` text tables into typed, deduped `stg` tables.
-- ---------------------------------------------------------------------
-- What this step proves: real-world data hygiene -- casting text dates,
-- normalising case, translating Portuguese categories, and collapsing
-- the duplicate review rows that trip up every first-timer on Olist.
-- =====================================================================

DROP SCHEMA IF EXISTS stg CASCADE;
CREATE SCHEMA stg;

-- 1. Customers --------------------------------------------------------
CREATE TABLE stg.customers AS
SELECT customer_id,
       customer_unique_id,
       customer_zip_code_prefix::INT      AS zip_code_prefix,
       INITCAP(TRIM(customer_city))       AS city,
       UPPER(TRIM(customer_state))        AS state
FROM raw.customers;

-- 2. Orders : cast 5 timestamps; empty strings -> NULL ----------------
-- ~3% of orders never reach the customer (cancelled, still in transit),
-- so order_delivered_customer_date is legitimately NULL -- keep the row.
CREATE TABLE stg.orders AS
SELECT order_id,
       customer_id,
       LOWER(TRIM(order_status))                                AS order_status,
       NULLIF(order_purchase_timestamp,'')::TIMESTAMP           AS order_purchase_ts,
       NULLIF(order_approved_at,'')::TIMESTAMP                  AS order_approved_ts,
       NULLIF(order_delivered_carrier_date,'')::TIMESTAMP       AS delivered_carrier_ts,
       NULLIF(order_delivered_customer_date,'')::TIMESTAMP      AS delivered_customer_ts,
       NULLIF(order_estimated_delivery_date,'')::TIMESTAMP      AS estimated_delivery_ts
FROM raw.orders
WHERE order_purchase_timestamp IS NOT NULL;

-- 3. Order items : numeric casts, item grain --------------------------
CREATE TABLE stg.order_items AS
SELECT order_id,
       order_item_id::INT       AS order_item_id,
       product_id,
       seller_id,
       NULLIF(shipping_limit_date,'')::TIMESTAMP AS shipping_limit_ts,
       price::NUMERIC(10,2)         AS price,
       freight_value::NUMERIC(10,2) AS freight_value
FROM raw.order_items;

-- 4. Payments : numeric casts -----------------------------------------
CREATE TABLE stg.order_payments AS
SELECT order_id,
       payment_sequential::INT          AS payment_sequential,
       LOWER(TRIM(payment_type))        AS payment_type,
       payment_installments::INT        AS payment_installments,
       payment_value::NUMERIC(10,2)     AS payment_value
FROM raw.order_payments;

-- 5. Reviews : DEDUPLICATE ----------------------------------------
-- The raw file contains a handful of order_ids with multiple review
-- rows. Keep the most recently answered review per order so downstream
-- joins stay 1:1 with orders.
CREATE TABLE stg.order_reviews AS
WITH ranked AS (
    SELECT review_id,
           order_id,
           review_score::INT AS review_score,
           NULLIF(review_creation_date,'')::TIMESTAMP    AS review_creation_ts,
           NULLIF(review_answer_timestamp,'')::TIMESTAMP AS review_answer_ts,
           ROW_NUMBER() OVER (
               PARTITION BY order_id
               ORDER BY NULLIF(review_answer_timestamp,'')::TIMESTAMP DESC NULLS LAST
           ) AS rn
    FROM raw.order_reviews
    WHERE review_score IS NOT NULL
)
SELECT review_id, order_id, review_score, review_creation_ts, review_answer_ts
FROM ranked
WHERE rn = 1;

-- 6. Products : translate category pt -> en ---------------------------
-- Untranslatable / missing categories collapse to 'unknown' so the
-- product dimension never drops a row on the join.
CREATE TABLE stg.products AS
SELECT p.product_id,
       COALESCE(NULLIF(t.product_category_name_english,''),
                NULLIF(p.product_category_name,''),
                'unknown')                       AS category,
       NULLIF(p.product_weight_g,'')::NUMERIC    AS weight_g,
       NULLIF(p.product_photos_qty,'')::INT      AS photos_qty
FROM raw.products p
LEFT JOIN raw.product_category_name_translation t
       ON p.product_category_name = t.product_category_name;

-- 7. Sellers ----------------------------------------------------------
CREATE TABLE stg.sellers AS
SELECT seller_id,
       seller_zip_code_prefix::INT   AS zip_code_prefix,
       INITCAP(TRIM(seller_city))    AS city,
       UPPER(TRIM(seller_state))     AS state
FROM raw.sellers;

-- 8. Geolocation : one representative lat/lng per zip prefix -----------
-- The raw file has ~1M rows (many points per prefix). Average them to a
-- single centroid so the prefix can act as a clean join key.
CREATE TABLE stg.geolocation AS
SELECT geolocation_zip_code_prefix::INT AS zip_code_prefix,
       AVG(geolocation_lat::NUMERIC)    AS lat,
       AVG(geolocation_lng::NUMERIC)    AS lng,
       UPPER(MAX(geolocation_state))    AS state
FROM raw.geolocation
WHERE geolocation_lat <> '' AND geolocation_lng <> ''
GROUP BY geolocation_zip_code_prefix;

-- Quick validation -----------------------------------------------------
SELECT 'orders kept'        AS metric, COUNT(*) AS value FROM stg.orders
UNION ALL SELECT 'reviews after dedup', COUNT(*) FROM stg.order_reviews
UNION ALL SELECT 'products w/ english cat',
       COUNT(*) FILTER (WHERE category <> 'unknown') FROM stg.products;
