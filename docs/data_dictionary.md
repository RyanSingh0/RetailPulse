# Data Dictionary — RetailPulse

Column-level reference for the Olist source tables (`raw`) and the
modeled star schema (`mart`). Source: *Brazilian E-Commerce Public
Dataset by Olist* (Kaggle), ~100K orders, Sept 2016 – Oct 2018.

---

## Source tables (`raw` schema)

### customers
| Column | Type | Notes |
|--------|------|-------|
| customer_id | text | Key per **order** (not per person). Joins to `orders`. |
| customer_unique_id | text | The real customer across orders. Use this for retention/RFM. |
| customer_zip_code_prefix | int | First 5 digits of ZIP; joins to geolocation. |
| customer_city / customer_state | text | City and 2-letter state (e.g. `SP`). |

### orders
| Column | Type | Notes |
|--------|------|-------|
| order_id | text | PK. |
| customer_id | text | FK → customers. |
| order_status | text | delivered, shipped, canceled, unavailable, … |
| order_purchase_timestamp | timestamp | When the order was placed. |
| order_approved_at | timestamp | Payment approved. |
| order_delivered_carrier_date | timestamp | Handed to logistics. |
| order_delivered_customer_date | timestamp | Delivered to customer (NULL if not yet / never). |
| order_estimated_delivery_date | timestamp | Promised date — basis of on-time %. |

### order_items
| Column | Type | Notes |
|--------|------|-------|
| order_id | text | FK → orders. |
| order_item_id | int | Sequence within the order (1..n). |
| product_id | text | FK → products. |
| seller_id | text | FK → sellers. |
| shipping_limit_date | timestamp | Seller's ship-by deadline. |
| price | numeric | Item price (R$). |
| freight_value | numeric | Shipping charged for the item (R$). |

### order_payments
| Column | Type | Notes |
|--------|------|-------|
| order_id | text | FK → orders (can be several rows per order). |
| payment_sequential | int | Payment number within the order. |
| payment_type | text | credit_card, boleto, voucher, debit_card. |
| payment_installments | int | Number of installments. |
| payment_value | numeric | Amount for that payment row (R$). |

### order_reviews
| Column | Type | Notes |
|--------|------|-------|
| review_id | text | Review identifier (not unique per order in raw). |
| order_id | text | FK → orders; deduped to 1:1 in `stg.order_reviews`. |
| review_score | int | 1–5 stars. |
| review_creation_date | timestamp | When the survey was sent. |
| review_answer_timestamp | timestamp | When the customer answered. |

### products
| Column | Type | Notes |
|--------|------|-------|
| product_id | text | PK. |
| product_category_name | text | **Portuguese** category — translated in `02_clean.sql`. |
| product_weight_g, product_*_cm, product_photos_qty | numeric | Physical/catalog attributes. |

### sellers
| Column | Type | Notes |
|--------|------|-------|
| seller_id | text | PK. |
| seller_zip_code_prefix | int | Joins to geolocation. |
| seller_city / seller_state | text | Seller location. |

### geolocation
| Column | Type | Notes |
|--------|------|-------|
| geolocation_zip_code_prefix | int | ~1M rows; many points per prefix. Averaged to a centroid in `stg.geolocation`. |
| geolocation_lat / geolocation_lng | numeric | Coordinates. |
| geolocation_city / geolocation_state | text | Place name. |

### product_category_name_translation
| Column | Type | Notes |
|--------|------|-------|
| product_category_name | text | Portuguese (join key). |
| product_category_name_english | text | English label used everywhere downstream. |

---

## Star schema (`mart` schema)

### fact_order_items  *(grain: one item sold)*
| Column | Type | Notes |
|--------|------|-------|
| order_id | text | Order the item belongs to. |
| order_item_id | int | Item sequence. |
| customer_key | text | FK → dim_customer (customer_unique_id). |
| product_key | text | FK → dim_product. |
| seller_key | text | FK → dim_seller. |
| date_key | date | FK → dim_date (month-truncated purchase date). |
| order_purchase_ts | timestamp | Purchase datetime. |
| delivered_customer_ts | timestamp | Delivery datetime (nullable). |
| estimated_delivery_ts | timestamp | Promised date. |
| order_status | text | Filtered to exclude canceled/unavailable. |
| price | numeric | Item price (R$). |
| freight_value | numeric | Freight (R$). |
| **gmv** | numeric | `price + freight_value` — the revenue measure. |
| delivery_days | numeric | Days from purchase to delivery (nullable). |
| delivered_on_time | boolean | `delivered ≤ estimated` (nullable). |
| review_score | int | 1–5 stars for the order (denormalised from reviews; nullable). |

### dim_date
`date_key` (PK), `year`, `month_no`, `year_month`, `month_name`, `quarter`.

### dim_customer
`customer_key` (PK = customer_unique_id), `zip_code_prefix`, `city`, `state`.

### dim_product
`product_key` (PK), `category` (English), `weight_g`, `photos_qty`.

### dim_seller
`seller_key` (PK), `city`, `state`.

---

## Conventions

- **Revenue = GMV = price + freight_value.** Computed on `order_items`,
  not `payments` (the two differ slightly; GMV is the consistent basis
  used across every query and measure).
- **Customer = `customer_unique_id`**, never `customer_id`.
- **Revenue scope** excludes `canceled` and `unavailable` orders.
