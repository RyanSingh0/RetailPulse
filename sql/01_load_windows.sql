-- =====================================================================
-- 01_load_windows.sql  ·  RetailPulse  (Windows / psql version)
-- Client-side \copy with absolute paths -- run this INSIDE psql after
-- you are connected to the retailpulse database:
--     \i C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/sql/01_load_windows.sql
-- Requires the 9 Kaggle CSVs in  data/raw/  (see data/README.md).
-- \copy runs as YOUR user, so no server file-permission issues.
-- =====================================================================

\copy raw.customers FROM 'C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/data/raw/olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.orders FROM 'C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/data/raw/olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.order_items FROM 'C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/data/raw/olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.order_payments FROM 'C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/data/raw/olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.order_reviews FROM 'C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/data/raw/olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.products FROM 'C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/data/raw/olist_products_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.sellers FROM 'C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/data/raw/olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.geolocation FROM 'C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/data/raw/olist_geolocation_dataset.csv' WITH (FORMAT csv, HEADER true)

\copy raw.product_category_name_translation FROM 'C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/data/raw/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true)

-- Verify the load
SELECT 'customers' AS table, COUNT(*) FROM raw.customers
UNION ALL SELECT 'orders',         COUNT(*) FROM raw.orders
UNION ALL SELECT 'order_items',    COUNT(*) FROM raw.order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM raw.order_payments
UNION ALL SELECT 'order_reviews',  COUNT(*) FROM raw.order_reviews
UNION ALL SELECT 'products',       COUNT(*) FROM raw.products
UNION ALL SELECT 'sellers',        COUNT(*) FROM raw.sellers
UNION ALL SELECT 'geolocation',    COUNT(*) FROM raw.geolocation;
