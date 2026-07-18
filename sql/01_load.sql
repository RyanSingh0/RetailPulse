-- =====================================================================
-- 01_load.sql  ·  RetailPulse
-- COPY the raw Kaggle CSVs into the landing tables created in 00_schema.
-- ---------------------------------------------------------------------
-- HOW TO RUN
--   Option A (psql, server-side COPY): edit the paths below to the
--   absolute location of your data/raw/ folder, then:
--       psql -d retailpulse -f sql/01_load.sql
--
--   Option B (recommended, client-side, no superuser needed): run each
--   command in psql with \copy instead of COPY, e.g.
--       \copy raw.customers FROM 'data/raw/olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true)
--
-- The order_reviews file ships as latin-1; if COPY complains about
-- encoding, add  ENCODING 'LATIN1'  to that one command.
-- =====================================================================

\set raw_dir 'data/raw/'

COPY raw.customers
    FROM :'raw_dir'  'olist_customers_dataset.csv'
    WITH (FORMAT csv, HEADER true);

COPY raw.orders
    FROM :'raw_dir'  'olist_orders_dataset.csv'
    WITH (FORMAT csv, HEADER true);

COPY raw.order_items
    FROM :'raw_dir'  'olist_order_items_dataset.csv'
    WITH (FORMAT csv, HEADER true);

COPY raw.order_payments
    FROM :'raw_dir'  'olist_order_payments_dataset.csv'
    WITH (FORMAT csv, HEADER true);

COPY raw.order_reviews
    FROM :'raw_dir'  'olist_order_reviews_dataset.csv'
    WITH (FORMAT csv, HEADER true, ENCODING 'LATIN1');

COPY raw.products
    FROM :'raw_dir'  'olist_products_dataset.csv'
    WITH (FORMAT csv, HEADER true);

COPY raw.sellers
    FROM :'raw_dir'  'olist_sellers_dataset.csv'
    WITH (FORMAT csv, HEADER true);

COPY raw.geolocation
    FROM :'raw_dir'  'olist_geolocation_dataset.csv'
    WITH (FORMAT csv, HEADER true);

COPY raw.product_category_name_translation
    FROM :'raw_dir'  'product_category_name_translation.csv'
    WITH (FORMAT csv, HEADER true);

-- Sanity check: expected canonical row counts (header excluded)
--   customers 99,441 | orders 99,441 | order_items 112,650 | payments 103,886
--   reviews 99,224   | products 32,951 | sellers 3,095 | geolocation 1,000,163
SELECT 'customers'   AS table, COUNT(*) FROM raw.customers
UNION ALL SELECT 'orders',        COUNT(*) FROM raw.orders
UNION ALL SELECT 'order_items',   COUNT(*) FROM raw.order_items
UNION ALL SELECT 'order_payments',COUNT(*) FROM raw.order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM raw.order_reviews
UNION ALL SELECT 'products',      COUNT(*) FROM raw.products
UNION ALL SELECT 'sellers',       COUNT(*) FROM raw.sellers
UNION ALL SELECT 'geolocation',   COUNT(*) FROM raw.geolocation;
