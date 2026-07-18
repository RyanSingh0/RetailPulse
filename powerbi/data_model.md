# Power BI Data Model — RetailPulse

A single-fact **star schema**. Power BI connects straight to the `mart`
schema in PostgreSQL (see `BUILD_GUIDE.md`), so the model below mirrors
`sql/03_star_schema.sql` one-to-one.

## Tables to import

| Table | Source (Postgres) | Role | Grain |
|-------|-------------------|------|-------|
| `fact_order_items` | `mart.fact_order_items` | Fact | one row per item sold |
| `dim_date` | `mart.dim_date` | Dimension | one row per day |
| `dim_customer` | `mart.dim_customer` | Dimension | one row per customer |
| `dim_product` | `mart.dim_product` | Dimension | one row per product |
| `dim_seller` | `mart.dim_seller` | Dimension | one row per seller |
| `rfm_segments` | `mart.rfm_segments` (`16_rfm_table.sql`) | Dimension | one row per customer |
| `cohort_retention` | `mart.cohort_retention` (`15_cohort_table.sql`) | Standalone | cohort × period grid |

> Tip: bring `review_score`, `delivery_days` and `delivered_on_time`
> into `fact_order_items` directly (they already exist on the fact in
> `03_star_schema.sql`) so the experience measures need no extra join.

## Relationships

```
              dim_date
                 │ 1
                 │
                 ▼ *
dim_customer *──► fact_order_items ◄──* dim_product
                 ▲ *
                 │
                 │ *
              dim_seller
```

| From (many) | To (one) | Key | Cardinality | Cross-filter |
|-------------|----------|-----|-------------|--------------|
| `fact_order_items[date_key]` | `dim_date[date_key]` | date_key | * : 1 | single |
| `fact_order_items[customer_key]` | `dim_customer[customer_key]` | customer_key | * : 1 | single |
| `fact_order_items[product_key]` | `dim_product[product_key]` | product_key | * : 1 | single |
| `fact_order_items[seller_key]` | `dim_seller[seller_key]` | seller_key | * : 1 | single |
| `rfm_segments[customer_key]` | `dim_customer[customer_key]` | customer_key | 1 : 1 | both |

`cohort_retention` is **standalone** (no relationship) — its visuals use
only its own columns.

All relationships are single-direction (fact filtered by dims) except
the optional `rfm` bridge. **Mark `dim_date` as the date table**
(Modeling → Mark as date table → `date_key`) so the time-intelligence
measures (`MoM`, `Rolling 3-Month`, `YTD`) work.

## Field formatting

| Field / Measure | Format |
|-----------------|--------|
| `Total Revenue`, `AOV`, `Revenue per Customer` | Currency, R$, 0 dp |
| `MoM Revenue Growth %`, `Retention Rate`, `On-Time Delivery %` | Percentage, 1 dp |
| `Avg Review Score` | Decimal, 2 dp |
| `Avg Delivery Days` | Decimal, 1 dp |
| `dim_date[year_month]` | Text, sort by a `YYYYMM` sort column |

## Measures

All measures live in `measures.dax`. Create one hidden **`_Measures`**
table (Home → Enter Data → empty table) and house every measure there so
they group cleanly in the field list.
