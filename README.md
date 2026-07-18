# RetailPulse: E-Commerce Analytics (SQL + Power BI)

**An end-to-end analytics build on ~100K real Brazilian e-commerce orders.
Raw CSVs → PostgreSQL star schema → analytical SQL → Power BI dashboard.**

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-336791?logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-window_functions_CTEs-025E8C)
![Power BI](https://img.shields.io/badge/Power_BI-DAX-F2C811?logo=powerbi&logoColor=black)
![Dataset](https://img.shields.io/badge/data-Olist_Kaggle-20BEFF)

### ▶️ [**View the live interactive dashboard**](https://app.powerbi.com/view?r=eyJrIjoiYTBmMDI3ZWMtMDExZC00MmM0LTk5ZTYtYjY4YTlhNTk4N2EyIiwidCI6ImQ1N2QzMmNjLWMxMjEtNDg4Zi1iMDdiLWRmZTcwNTY4MGM3MSIsImMiOjN9&pageName=f28b4b4a651ff21ecd55)

*(Published to Power BI Service · public Olist sample data · no login required)*

---

## Overview

RetailPulse answers the questions a marketplace manager actually asks. How
fast are we growing? Do customers come back? Who are the best customers?
What makes a good review? Where is the money? Each one turns into a
business question, a SQL query, a visual and a plain-English takeaway.

The data is the [Olist Brazilian E-Commerce public dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce):
nine linked tables and roughly 100K orders placed between September 2016
and October 2018. It's relational and realistically messy, with string
dates, Portuguese category names, duplicate review rows and multi-item
orders, so getting it analysis-ready is half the job.

**After cleaning:** 98,199 valid orders · 94,983 unique customers ·
**R$15.74M** revenue (GMV) · **R$160.24** average order value.

---

## Key insights

1. **Olist is an acquisition business, not a loyalty one.** Only **3.0%**
   of customers ever place a second order. 92,096 of 94,983 are
   one-and-done. Cohort retention drops below **0.5%** by the following
   month and stays there. Growth comes from new customers and a great
   first order, not from people coming back.

2. **Delivery speed is the biggest lever on satisfaction.** Orders
   delivered in **0-3 days average 4.46★**, while orders taking **22+ days
   average just 3.06★**. Looked at against the promised date, on-time
   orders score **4.29★ versus 2.57★ when they run late**. Missing the
   promise costs roughly **1.7 stars**.

3. **Revenue grows on volume, not basket size.** Monthly revenue climbed
   from about R$140K (Jan 2017) to a R$1.0-1.15M plateau by mid-2018 while
   AOV held flat near R$160. Almost all of the growth came from *more
   orders*.

4. **The business leans heavily on one region.** São Paulo alone is
   **37.4%** of revenue and the Southeast dominates overall. That density
   is great for logistics but a real single-region risk.

5. **A small group of customers drives most of the money.** The top two
   RFM segments, "Champions" (recent and high spend) and "Big Spenders",
   are about **40% of customers but 74% of revenue**. Since ~97% of
   customers buy only once, the segmentation leans on Recency and Monetary
   and keeps frequency as a simple repeat flag. That's an honest call the
   data forces rather than a textbook one.

---

## Architecture

```
Kaggle CSVs  ──►  PostgreSQL          ──►  SQL analysis layer   ──►  Power BI      ──►  Power BI Service
(data/raw/)       raw → clean → star       sql/ : KPIs, cohort,      model + DAX        (live link)
                  (00-03)                   RFM, product, geo         + 4 pages
```

| Layer | Tool | What it shows |
|-------|------|----------------|
| Load + model | PostgreSQL | schema design, typing, keys, a clean star schema |
| Analysis | SQL | window functions, CTEs, cohort retention, RFM |
| Dashboard | Power BI + DAX | data modeling, measures, visual design |
| Publish | Power BI Service | a live deliverable, not just screenshots |

---

## SQL highlights

Every file in [`sql/`](sql/) is commented and framed as a business
question. Two that show the range:

**Cohort retention** ([`11_cohort_retention.sql`](sql/11_cohort_retention.sql)).
Tag each customer with their first-purchase month, then count who comes
back in each following month.

```sql
WITH customer_months AS (
    SELECT DISTINCT customer_key, date_key AS active_month
    FROM mart.fact_order_items
),
first_purchase AS (
    SELECT customer_key, MIN(active_month) AS cohort_month
    FROM customer_months GROUP BY customer_key
),
activity AS (
    SELECT f.cohort_month, cm.customer_key,
           (EXTRACT(YEAR  FROM age(cm.active_month, f.cohort_month)) * 12
          + EXTRACT(MONTH FROM age(cm.active_month, f.cohort_month)))::INT AS period_index
    FROM customer_months cm JOIN first_purchase f USING (customer_key)
)
SELECT cohort_month, period_index,
       COUNT(DISTINCT customer_key) AS active_customers
FROM activity GROUP BY cohort_month, period_index;
```

**RFM segmentation** ([`12_rfm_segmentation.sql`](sql/12_rfm_segmentation.sql)).
Score Recency, Frequency and Monetary into quintiles with `NTILE(5)`, then
bucket the scores into named segments.

```sql
NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
NTILE(5) OVER (ORDER BY frequency   ASC ) AS f_score,
NTILE(5) OVER (ORDER BY monetary    ASC ) AS m_score
-- → CASE ... 'Champions' / 'Big Spenders' / 'At Risk' / 'Hibernating' ...
```

The rest of the set: [`10_kpis`](sql/10_kpis.sql) (MoM growth with
`LAG()`, cumulative `SUM() OVER`), [`11_cohort_retention`](sql/11_cohort_retention.sql),
[`12_rfm_segmentation`](sql/12_rfm_segmentation.sql),
[`13_product_category`](sql/13_product_category.sql) (RANK plus the
delivery-vs-review analysis) and [`14_geography`](sql/14_geography.sql).

---

## Dashboard pages

Four pages built on the star schema, with custom DAX measures
([`powerbi/measures.dax`](powerbi/measures.dax)) and three synced slicers
(date, state and category). The previews below come straight from the SQL
outputs. Swap in your own Power BI screenshots after publishing.

**Page 1: Executive Overview** · revenue trend, MoM growth, KPI cards and top categories

**Page 2: Customers & Retention** · repeat-vs-one-time, cohort heatmap and RFM segments

**Page 3: Products & Categories** · category ranking and the delivery-vs-review finding

**Page 4: Geography** · revenue by state and regional roll-up

> Final Power BI screenshots go in `assets/` as `dashboard_overview.png`,
> `dashboard_cohort.png`, `dashboard_product.png` and `dashboard_geo.png`.

---

## How to reproduce

1. **Get the data.** Download the nine Olist CSVs from Kaggle into
   `data/raw/`. [`data/README.md`](data/README.md) lists the exact steps
   and filenames.
2. **Build the database.** Create a `retailpulse` Postgres DB and run these
   in order:
   ```bash
   psql -d retailpulse -f sql/00_schema.sql
   psql -d retailpulse -f sql/01_load.sql      # or \copy (see file header)
   psql -d retailpulse -f sql/02_clean.sql
   psql -d retailpulse -f sql/03_star_schema.sql
   ```
3. **Run the analysis.** Execute `sql/10` through `sql/17` to reproduce
   every number in this README and build the tables the dashboard reads.
4. **Build the dashboard.** Follow [`powerbi/BUILD_GUIDE.md`](powerbi/BUILD_GUIDE.md):
   connect Power BI to `mart`, add the measures, build the four pages and
   publish.

> On Windows? [`RUN_ON_WINDOWS.md`](RUN_ON_WINDOWS.md) has copy-paste psql
> steps with the paths already filled in.

---

## Repo layout

```
retailpulse/
├── README.md                     ← you are here
├── RUN_ON_WINDOWS.md             Windows quickstart (psql, paths baked in)
├── data/
│   └── README.md                 Kaggle download step (raw CSVs gitignored)
├── sql/
│   ├── 00_schema.sql             raw landing tables
│   ├── 01_load.sql               COPY the CSVs  (·_windows.sql = \copy variant)
│   ├── 02_clean.sql              cast, dedup, translate categories
│   ├── 03_star_schema.sql        fact_order_items + 4 dimensions
│   ├── 10_kpis.sql               revenue, AOV, MoM growth, running total
│   ├── 11_cohort_retention.sql   first-purchase cohort grid
│   ├── 12_rfm_segmentation.sql   R×M segments (NTILE) + repeat flag
│   ├── 13_product_category.sql   category ranking + delivery vs review
│   ├── 14_geography.sql          revenue by state / region / city
│   ├── 15_cohort_table.sql       materialised cohort grid → Power BI
│   ├── 16_rfm_table.sql          per-customer RFM table → Power BI
│   ├── 17_dim_state.sql          state names + region + lat/long (map)
│   └── UPDATES.sql               incremental patches for an existing DB
├── powerbi/
│   ├── RetailPulse.pbix          the Power BI report
│   ├── measures.dax              all DAX measures + calculated columns
│   ├── data_model.md             tables, relationships, formatting
│   └── BUILD_GUIDE.md            connect → model → 4 pages → publish
├── assets/
│   ├── dashboard_hero.png        README hero (built from SQL outputs)
│   ├── previews/                 per-chart previews from the SQL
│   └── dashboard_*.png           live Power BI page screenshots
└── docs/data_dictionary.md       column-level reference
```

---

## What I'd do next

- **Revenue forecast.** The monthly series is clean, so a simple
  Prophet or ARIMA forecast would sit nicely on the overview page.
- **Churn / next-purchase model.** Repeats are rare, so predicting *which*
  first-time buyers will return is the high-value extension.
- **Delivery SLA model.** Put a number on the review and revenue cost of
  each late day to help prioritise logistics spend.
- **Seller scorecard.** A fifth page ranking sellers on revenue, on-time %
  and review score.

---

## Resume bullet

> **RetailPulse: E-Commerce Analytics (SQL + Power BI)** · [live dashboard](https://app.powerbi.com/view?r=eyJrIjoiYTBmMDI3ZWMtMDExZC00MmM0LTk5ZTYtYjY4YTlhNTk4N2EyIiwidCI6ImQ1N2QzMmNjLWMxMjEtNDg4Zi1iMDdiLWRmZTcwNTY4MGM3MSIsImMiOjN9&pageName=f28b4b4a651ff21ecd55)
> - Modeled a 9-table, ~100K-order Brazilian e-commerce dataset into a
>   star schema in **PostgreSQL**. Wrote analytical SQL using window
>   functions, CTEs, cohort retention and **RFM segmentation** (`NTILE`).
> - Built and **published** an interactive **Power BI** dashboard (4 pages,
>   with DAX measures for MoM growth, retention rate and rolling revenue).
>   Found that **late deliveries cut average review scores from 4.29★ to
>   2.57★** and that just **3% of customers ever reorder**, which reframes
>   the business around acquisition and the first-order experience.
> - **Stack:** PostgreSQL, SQL (window functions and CTEs), Power BI and DAX

---

*Data: Olist Brazilian E-Commerce Public Dataset (Kaggle, public). Built as a portfolio piece with SQL and Power BI.*
