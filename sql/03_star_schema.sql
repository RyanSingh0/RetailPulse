-- =====================================================================
-- 03_star_schema.sql  ·  RetailPulse
-- Dimensional model: one fact at the order-ITEM grain + four dimensions.
-- ---------------------------------------------------------------------
-- Grain choice: fact_order_items = one row per physical item sold.
-- Price and freight live at the item level in Olist, so this is the
-- finest grain that still carries money -- it rolls up cleanly to order,
-- customer, category, seller, state and month. Power BI connects to this
-- star directly (star schema = fast, intuitive DAX).
--
--        dim_date ─┐
--     dim_customer ─┤
--      dim_product ─┼──  fact_order_items
--       dim_seller ─┘
-- =====================================================================

DROP SCHEMA IF EXISTS mart CASCADE;
CREATE SCHEMA mart;

-- DIM: DATE -----------------------------------------------------------
-- Generated from the order date span so Power BI has a real, contiguous
-- calendar to drive time-intelligence DAX (MoM, rolling, YTD).
CREATE TABLE mart.dim_date AS
WITH bounds AS (
    SELECT date_trunc('month', MIN(order_purchase_ts))::DATE AS d0,
           date_trunc('month', MAX(order_purchase_ts))::DATE AS d1
    FROM stg.orders
)
SELECT d::DATE                                   AS date_key,
       EXTRACT(YEAR  FROM d)::INT                AS year,
       EXTRACT(MONTH FROM d)::INT                AS month_no,
       TO_CHAR(d,'YYYY-MM')                      AS year_month,
       TO_CHAR(d,'Mon')                          AS month_name,
       EXTRACT(QUARTER FROM d)::INT              AS quarter
FROM bounds,
     generate_series(bounds.d0, bounds.d1 + INTERVAL '1 month', INTERVAL '1 day') AS g(d);

ALTER TABLE mart.dim_date ADD PRIMARY KEY (date_key);

-- DIM: CUSTOMER -------------------------------------------------------
-- Keyed on customer_unique_id (the real person), not the per-order id.
-- Includes a Brazil macro-region derived from state (feeds the Geography
-- page's regional matrix).
CREATE TABLE mart.dim_customer AS
SELECT customer_unique_id                          AS customer_key,
       MAX(zip_code_prefix)                        AS zip_code_prefix,
       MAX(city)                                   AS city,
       MAX(state)                                  AS state,
       CASE
           WHEN MAX(state) IN ('SP','RJ','MG','ES')                THEN 'Southeast'
           WHEN MAX(state) IN ('RS','PR','SC')                     THEN 'South'
           WHEN MAX(state) IN ('BA','PE','CE','MA','PB','RN','AL','SE','PI') THEN 'Northeast'
           WHEN MAX(state) IN ('GO','DF','MT','MS')                THEN 'Center-West'
           WHEN MAX(state) IN ('AM','PA','RO','TO','AC','AP','RR') THEN 'North'
           ELSE 'Other'
       END                                         AS region
FROM stg.customers
GROUP BY customer_unique_id;

ALTER TABLE mart.dim_customer ADD PRIMARY KEY (customer_key);

-- DIM: PRODUCT --------------------------------------------------------
CREATE TABLE mart.dim_product AS
SELECT product_id        AS product_key,
       category,
       weight_g,
       photos_qty
FROM stg.products;

ALTER TABLE mart.dim_product ADD PRIMARY KEY (product_key);

-- DIM: SELLER ---------------------------------------------------------
CREATE TABLE mart.dim_seller AS
SELECT seller_id   AS seller_key,
       city,
       state
FROM stg.sellers;

ALTER TABLE mart.dim_seller ADD PRIMARY KEY (seller_key);

-- FACT: ORDER ITEMS ---------------------------------------------------
-- Scope: exclude cancelled / unavailable orders so revenue == realised
-- GMV. Each row carries the foreign keys to all four dims plus the two
-- additive measures (price, freight) and a few useful order-level dates.
CREATE TABLE mart.fact_order_items AS
SELECT oi.order_id,
       oi.order_item_id,
       c.customer_unique_id                         AS customer_key,
       oi.product_id                                AS product_key,
       oi.seller_id                                 AS seller_key,
       date_trunc('month', o.order_purchase_ts)::DATE AS date_key,
       o.order_purchase_ts,
       o.delivered_customer_ts,
       o.estimated_delivery_ts,
       o.order_status,
       oi.price,
       oi.freight_value,
       (oi.price + oi.freight_value)                AS gmv,
       -- delivery lead time in days (NULL when not yet delivered)
       CASE WHEN o.delivered_customer_ts IS NOT NULL
            THEN EXTRACT(EPOCH FROM (o.delivered_customer_ts - o.order_purchase_ts))/86400.0
       END                                          AS delivery_days,
       -- was it delivered on or before the promised date?
       CASE WHEN o.delivered_customer_ts IS NOT NULL AND o.estimated_delivery_ts IS NOT NULL
            THEN (o.delivered_customer_ts <= o.estimated_delivery_ts)
       END                                          AS delivered_on_time,
       -- order's review score, denormalised onto the fact so the
       -- delivery-vs-review analysis needs no extra table / bi-di filter.
       -- (At item grain a multi-item order repeats its score per item --
       --  fine for AVG; the SQL in 13_* de-dups on order_id where exact.)
       r.review_score                               AS review_score
FROM stg.order_items oi
JOIN stg.orders        o ON oi.order_id   = o.order_id
JOIN stg.customers     c ON o.customer_id = c.customer_id
LEFT JOIN stg.order_reviews r ON oi.order_id = r.order_id
WHERE o.order_status NOT IN ('canceled','unavailable');

-- Foreign keys document the model (and let Power BI auto-detect rels).
ALTER TABLE mart.fact_order_items ADD FOREIGN KEY (date_key)     REFERENCES mart.dim_date(date_key);
ALTER TABLE mart.fact_order_items ADD FOREIGN KEY (customer_key) REFERENCES mart.dim_customer(customer_key);
ALTER TABLE mart.fact_order_items ADD FOREIGN KEY (product_key)  REFERENCES mart.dim_product(product_key);
ALTER TABLE mart.fact_order_items ADD FOREIGN KEY (seller_key)   REFERENCES mart.dim_seller(seller_key);

CREATE INDEX ix_fact_date     ON mart.fact_order_items(date_key);
CREATE INDEX ix_fact_customer ON mart.fact_order_items(customer_key);
CREATE INDEX ix_fact_product  ON mart.fact_order_items(product_key);

-- Headline check (expect ~98,199 orders / R$15.7M GMV / AOV ~160) ------
SELECT COUNT(DISTINCT order_id)                       AS orders,
       COUNT(DISTINCT customer_key)                   AS customers,
       ROUND(SUM(gmv),0)                              AS revenue,
       ROUND(SUM(gmv)/COUNT(DISTINCT order_id),2)     AS aov
FROM mart.fact_order_items;
