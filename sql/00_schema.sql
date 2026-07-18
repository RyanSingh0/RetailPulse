-- =====================================================================
-- 00_schema.sql  ·  RetailPulse
-- Raw landing tables for the Olist Brazilian E-Commerce dataset.
-- ---------------------------------------------------------------------
-- Strategy: load the CSVs EXACTLY as they arrive (text-friendly types,
-- no constraints) into a `raw` schema, then cast / dedup / key them in
-- 02_clean.sql. Keeping the landing zone permissive means a bad row in
-- a 1M-line file never blocks the load -- we fix data in SQL, on purpose,
-- because cleaning messy input is part of the job this project shows.
--
-- Run order:  00_schema -> 01_load -> 02_clean -> 03_star_schema -> 10..14
-- Target:     PostgreSQL 14+
-- =====================================================================

DROP SCHEMA IF EXISTS raw CASCADE;
CREATE SCHEMA raw;

-- 1. Customers --------------------------------------------------------
-- Note: customer_id is per-ORDER; customer_unique_id is the real person.
-- This distinction is the #1 gotcha in Olist analysis.
CREATE TABLE raw.customers (
    customer_id              TEXT,
    customer_unique_id       TEXT,
    customer_zip_code_prefix TEXT,
    customer_city            TEXT,
    customer_state           TEXT
);

-- 2. Orders -----------------------------------------------------------
-- All five timestamps land as TEXT and are cast in 02_clean.sql so a
-- malformed/empty date can never abort the COPY.
CREATE TABLE raw.orders (
    order_id                      TEXT,
    customer_id                   TEXT,
    order_status                  TEXT,
    order_purchase_timestamp      TEXT,
    order_approved_at             TEXT,
    order_delivered_carrier_date  TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT
);

-- 3. Order items (one row per physical item -> grain of the fact) -----
CREATE TABLE raw.order_items (
    order_id            TEXT,
    order_item_id       TEXT,
    product_id          TEXT,
    seller_id           TEXT,
    shipping_limit_date TEXT,
    price               TEXT,
    freight_value       TEXT
);

-- 4. Payments (one order can have several payment rows) ---------------
CREATE TABLE raw.order_payments (
    order_id             TEXT,
    payment_sequential   TEXT,
    payment_type         TEXT,
    payment_installments TEXT,
    payment_value        TEXT
);

-- 5. Reviews ----------------------------------------------------------
CREATE TABLE raw.order_reviews (
    review_id               TEXT,
    order_id                TEXT,
    review_score            TEXT,
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    TEXT,
    review_answer_timestamp TEXT
);

-- 6. Products (category arrives in Portuguese -> translated in clean) --
CREATE TABLE raw.products (
    product_id                 TEXT,
    product_category_name      TEXT,
    product_name_lenght        TEXT,   -- original misspelling preserved on purpose
    product_description_lenght TEXT,
    product_photos_qty         TEXT,
    product_weight_g           TEXT,
    product_length_cm          TEXT,
    product_height_cm          TEXT,
    product_width_cm           TEXT
);

-- 7. Sellers ----------------------------------------------------------
CREATE TABLE raw.sellers (
    seller_id              TEXT,
    seller_zip_code_prefix TEXT,
    seller_city            TEXT,
    seller_state           TEXT
);

-- 8. Geolocation (zip prefix -> lat/lng; many rows per prefix) --------
CREATE TABLE raw.geolocation (
    geolocation_zip_code_prefix TEXT,
    geolocation_lat             TEXT,
    geolocation_lng             TEXT,
    geolocation_city            TEXT,
    geolocation_state           TEXT
);

-- 9. Category translation (pt -> en lookup) ---------------------------
CREATE TABLE raw.product_category_name_translation (
    product_category_name         TEXT,
    product_category_name_english TEXT
);
