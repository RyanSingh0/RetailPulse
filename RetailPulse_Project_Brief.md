# RetailPulse — Project Brief

**A SQL + Power BI end-to-end e-commerce analytics project**
Author: Aryan Meena · Target: Data Analyst / Data Scientist portfolio piece · Timeline: ~1–2 weeks

---

## 1. Why this project exists

Every resume review flagged the same gap: SQL and BI dashboards have no project evidence behind them. They appear in the skills list, but every existing project is Python/R/Spark/ML. A recruiter screening for an analyst role cannot tell, from the current portfolio, whether the candidate can write a window function or build a dashboard a stakeholder would actually use.

RetailPulse closes that gap with a single artifact that proves three things at once:

1. **SQL depth** — not `SELECT *`, but the analyst-grade patterns that show up in technical screens: window functions, CTEs, cohort retention, segmentation.
2. **BI / dashboarding** — a multi-page Power BI report with real DAX measures, not drag-and-drop defaults.
3. **Business storytelling** — the ability to turn a question a manager would ask into a query, a visual, and an insight.

The goal is not a complex model. It is to look like real analyst work on a dataset recruiters recognize.

---

## 2. Goals & success criteria

The project is "done" when each of these is true:

- A relational database is loaded, cleaned, and modeled in **PostgreSQL** from raw CSVs.
- A `sql/` folder contains **commented, business-framed queries** demonstrating window functions, CTEs, cohort retention, and RFM segmentation.
- A **Power BI dashboard** (3–4 pages) is built on the data, including at least **4–5 custom DAX measures**.
- The dashboard is **published to Power BI Service** with a live, shareable link.
- A **README** frames the whole thing as *business question → SQL → visual → insight*, with embedded screenshots and the live link at the top.
- The repo is added to the resume, portfolio site, GitHub guide, and LinkedIn.

**Quality bar:** a reviewer should be able to click the live dashboard, read the README in 3 minutes, and come away believing "this person can do analyst work day one."

---

## 3. Dataset

**Olist Brazilian E-Commerce Public Dataset** (Kaggle, free).

Why this one:
- **Relational** — ~9 linked tables (orders, order_items, customers, products, sellers, payments, reviews, geolocation, category translations). This forces real JOINs instead of single-flat-file analysis.
- **Recognizable** — a very common portfolio dataset, so reviewers immediately understand the schema.
- **Rich dimensions** — time (order timestamps), geography (state/city), customer, product category, seller, payment, and review score. Enough to build cohorts, segments, and a geographic view.
- **Realistically messy** — date columns as strings, missing review comments, multi-item orders, Portuguese category names needing translation. Cleaning it is itself a skill to show.

Scale: ~100K orders, ~112K order items, spanning 2016–2018. Big enough to be credible, small enough to load on a laptop.

> Download: search Kaggle for "Brazilian E-Commerce Public Dataset by Olist." Keep the raw CSVs in a `data/raw/` folder (and `.gitignore` them — don't commit raw data; document the download step in the README instead).

---

## 4. Architecture

```
Kaggle CSVs  ──►  PostgreSQL  ──►  SQL analysis layer  ──►  Power BI  ──►  Power BI Service
(data/raw/)       (load + clean    (sql/ : views &          (model +        (live link)
                   + star schema)   analytical queries)      DAX + pages)
```

Each layer maps to a skill a recruiter screens for:

| Layer | Tool | What it proves |
|-------|------|----------------|
| Load + model | PostgreSQL | schema design, data types, keys, a clean star schema |
| Analysis | SQL | window functions, CTEs, cohort/RFM logic |
| Dashboard | Power BI + DAX | data modeling, measures, visual design, UX |
| Publish | Power BI Service | the deliverable is live, not just screenshots |

---

## 5. Deliverables (the repo)

```
retailpulse/
├── README.md                  ← business-question framing, screenshots, LIVE LINK at top
├── data/
│   └── raw/                    (gitignored; README documents the Kaggle download)
├── sql/
│   ├── 00_schema.sql           CREATE TABLEs + types + primary/foreign keys
│   ├── 01_load.sql             COPY raw CSVs into tables
│   ├── 02_clean.sql            type casts, dedup, fix dates, translate categories
│   ├── 03_star_schema.sql      fact_orders + dim_customer / dim_product / dim_date / dim_seller
│   ├── 10_kpis.sql             revenue, orders, AOV, MoM growth (window functions)
│   ├── 11_cohort_retention.sql cohort analysis by first-purchase month
│   ├── 12_rfm_segmentation.sql Recency/Frequency/Monetary with NTILE()
│   ├── 13_product_category.sql category revenue, ranking, delivery vs. review score
│   └── 14_geography.sql        revenue & customers by state
├── powerbi/
│   └── RetailPulse.pbix        the Power BI file
├── assets/
│   ├── dashboard_overview.png
│   ├── dashboard_cohort.png
│   ├── dashboard_product.png
│   └── dashboard_geo.png
└── docs/
    └── data_dictionary.md      column-level description of each table
```

---

## 6. The SQL layer — what to actually write

This is the part that gets you past analyst SQL screens. Aim for queries that are *commented* and *framed as a business question*. Minimum set:

**KPIs & growth (`10_kpis.sql`)**
- Total revenue, order count, average order value (AOV).
- **Month-over-month revenue growth** using `LAG()` over an ordered month series.
- **Running / cumulative revenue** using `SUM() OVER (ORDER BY month)`.

**Cohort retention (`11_cohort_retention.sql`)** — the single most impressive analyst SQL pattern.
- Assign each customer a cohort = month of their **first** purchase (via a CTE + `MIN(order_date)`).
- For each subsequent month, count how many of that cohort purchased again.
- Output a cohort-month × period grid → becomes the retention heatmap in Power BI.

**RFM segmentation (`12_rfm_segmentation.sql`)**
- For each customer compute **Recency** (days since last order), **Frequency** (order count), **Monetary** (total spend).
- Score each into quintiles with `NTILE(5) OVER (ORDER BY ...)`.
- Bucket into segments (e.g., "Champions," "At Risk," "New") from the combined scores.

**Product & category (`13_product_category.sql`)**
- Revenue by category over time; top-N categories with `RANK()`.
- A genuinely interesting business question: **does faster delivery correlate with higher review scores?** (JOIN orders → reviews, bucket delivery time, average review score per bucket.)

**Geography (`14_geography.sql`)**
- Revenue, order count, and customer count by state → feeds the map page.

> Pattern to follow in every file: a comment block stating the business question, then the query, then a one-line note on what the result shows. That framing is what separates "knows SQL syntax" from "thinks like an analyst."

---

## 7. The Power BI layer — pages & measures

**Page 1 — Executive Overview**
KPI cards (Total Revenue, Orders, AOV, Active Customers, Retention Rate), a revenue-over-time line, top categories bar, and a month-over-month growth indicator.

**Page 2 — Customers & Retention**
The cohort retention heatmap (matrix visual), RFM segment breakdown (how many customers per segment, revenue per segment), repeat-vs-one-time customer split.

**Page 3 — Products & Categories**
Category revenue ranking, average review score by category, the delivery-time-vs-review-score finding, best/worst sellers.

**Page 4 — Geography**
Brazil map (filled map by state), revenue and customers by region, regional AOV.

**DAX measures to write (at least 4–5 — recruiters look for these specifically):**
- `Total Revenue = SUMX(...)`
- `MoM Revenue Growth % =` using `DATEADD` / `CALCULATE`
- `Retention Rate =` repeat customers ÷ cohort size
- `AOV = [Total Revenue] / [Total Orders]`
- `Rolling 3-Month Revenue =` using `CALCULATE` + `DATESINRANGE`

> Add a few slicers (date range, state, category) so the dashboard is interactive. Keep one consistent color theme. The visual polish matters — it's a *design* signal as much as a data one.

---

## 8. The README — structure

Frame everything around questions, not tools. Suggested sections:

1. **Live dashboard link** (top, impossible to miss) + one hero screenshot.
2. **Overview** — one paragraph: what business questions this answers.
3. **Key insights** — 3–4 bullet findings *with numbers* ("repeat customers drove X% of revenue from Y% of the base"; "orders delivered in <X days averaged Z higher review scores").
4. **Architecture** — the CSV → Postgres → SQL → Power BI diagram.
5. **SQL highlights** — show 1–2 of the best queries (cohort, RFM) in fenced blocks.
6. **Dashboard pages** — the four screenshots with one-line captions.
7. **How to reproduce** — Kaggle download → run `sql/` in order → open `.pbix`.
8. **What I'd do next** — honest extensions (forecast revenue, churn model).

---

## 9. Build plan (1–2 weeks)

| Day(s) | Focus | Output |
|--------|-------|--------|
| 1 | Download data, install PostgreSQL, load raw CSVs | tables populated |
| 2 | Clean + cast types, translate categories, dedup | clean tables |
| 3 | Design + build star schema (fact + dims) | `03_star_schema.sql` |
| 4–5 | Write the analytical SQL (KPIs, cohort, RFM, product, geo) | `sql/10–14` |
| 6 | Connect Power BI to Postgres, build the data model + relationships | model in `.pbix` |
| 7 | Write DAX measures | measures done |
| 8–9 | Build the 4 dashboard pages, style, add slicers | dashboard complete |
| 10 | Publish to Power BI Service, capture screenshots | live link |
| 11 | Write README + data dictionary | repo polished |
| 12 | Add to resume / portfolio / GitHub guide / LinkedIn | shipped |

---

## 10. Resume bullet (draft — fill in your real numbers after building)

> **RetailPulse — E-Commerce Analytics (SQL + Power BI)** · github.com/RyanSingh0/retailpulse
> - Modeled a 9-table, ~100K-order Brazilian e-commerce dataset into a star schema in **PostgreSQL**; wrote analytical SQL using window functions, CTEs, cohort-retention, and **RFM customer segmentation** (`NTILE`).
> - Built an interactive **Power BI** dashboard (4 pages, custom DAX measures: MoM growth, retention rate, rolling revenue) published to Power BI Service; surfaced that [INSERT REAL FINDING, e.g. "repeat customers drove 38% of revenue from 11% of the base"].
> - **Stack:** PostgreSQL, SQL (window functions, CTEs), Power BI, DAX

---

## 11. Tools checklist (you're on Windows — all native)

- [ ] PostgreSQL + pgAdmin (or DBeaver) — free
- [ ] Power BI Desktop — free, Windows-native
- [ ] Power BI Service account (free tier) — for publishing the live link
- [ ] Kaggle account — for the dataset
- [ ] Git / GitHub — repo

> Note for the README: the published Power BI Service link on the free tier is shareable, but "Publish to web" makes it fully public (good for a portfolio). Be aware the dataset is public sample data, so there's no privacy concern in making it public.
```
