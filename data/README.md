# Data — download step

The raw CSVs are **not committed** (see `.gitignore`). Reproduce them in
two minutes:

1. Create a free [Kaggle](https://www.kaggle.com) account.
2. Download the **Brazilian E-Commerce Public Dataset by Olist**:
   https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
3. Unzip all nine CSVs into **`data/raw/`**:

```
data/raw/
├── olist_customers_dataset.csv
├── olist_geolocation_dataset.csv
├── olist_order_items_dataset.csv
├── olist_order_payments_dataset.csv
├── olist_order_reviews_dataset.csv
├── olist_orders_dataset.csv
├── olist_products_dataset.csv
├── olist_sellers_dataset.csv
└── product_category_name_translation.csv
```

4. Run the SQL in order (`sql/00` → `sql/03`) to build the database.

Expected row counts after load: customers 99,441 · orders 99,441 ·
order_items 112,650 · payments 103,886 · reviews 99,224 · products
32,951 · sellers 3,095 · geolocation 1,000,163.
