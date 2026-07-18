# Power BI Build & Publish Guide — RetailPulse

Everything except the `.pbix` is done for you: the data is modeled in
PostgreSQL, the measures are in `measures.dax`, the page layouts are
specified below. This guide takes the report from empty to a live,
shareable link in about **45–60 minutes**.

> Why no `.pbix` in the repo yet: Power BI Desktop is a Windows GUI app
> and publishing needs your own Power BI account. Follow the steps; drop
> the four screenshots into `assets/` and the live link into `README.md`.

---

## 0. Prerequisites (all free)

- PostgreSQL with the RetailPulse database built (`sql/00`→`03` run).
- **Power BI Desktop** (Microsoft Store).
- A **Power BI Service** account (sign in with a work/school or free email).
- The **Npgsql** connector (Power BI ships with the PostgreSQL connector;
  if prompted, install Npgsql from the dialog).

---

## 1. Connect to PostgreSQL  (~5 min)

1. **Home → Get Data → PostgreSQL database.**
2. Server `localhost`, Database `retailpulse`.
3. **Data Connectivity mode: Import** (the data is small — import is
   faster and lets you publish without a gateway).
4. In Navigator tick: `mart.fact_order_items`, `mart.dim_date`,
   `mart.dim_customer`, `mart.dim_product`, `mart.dim_seller`.
   *(Optional: your RFM export table and `stg.order_reviews`.)*
5. **Load.**

---

## 2. Model the star  (~5 min)

1. Open **Model view**. Power BI auto-detects the FKs from
   `03_star_schema.sql`; confirm the four `* : 1` relationships in
   `data_model.md` exist (drag keys to create any that are missing).
2. Select `dim_date` → **Table tools → Mark as date table** → `date_key`.
3. Hide foreign-key columns on the fact from report view (right-click →
   Hide) to keep the field list clean.

---

## 3. Add the measures  (~10 min)

1. **Home → Enter data** → create an empty table named `_Measures` → Load.
2. Open `measures.dax`. For each block: select `_Measures` →
   **New measure** → paste → Enter.
3. Set the format for each measure per the table in `data_model.md`
   (currency / percentage / decimals).

---

## 4. Theme  (~3 min)

**View → Themes → Browse for themes** → pick or import one accent color
(this repo uses a blue `#1F77B4` primary with an orange `#E8743B`
highlight). Keep ONE accent across all four pages — consistency reads as
"designed", not "default".

---

## 5. Build the four pages

### Prerequisites — do these ONCE before building the pages

Some visuals need a table, column, or field that isn't in the base star
schema. Set them all up first so nothing is missing mid-build:

**A. SQL to run** (in psql, connected to `retailpulse`), then **Refresh**
in Power BI so the new tables/columns appear:

| Run | Builds | Needed for |
|-----|--------|------------|
| `sql/15_cohort_table.sql` | table `mart.cohort_retention` | Page 2 cohort matrix |
| `sql/16_rfm_table.sql` | table `mart.rfm_segments` | Page 2 RFM + repeat/one-time |
| `sql/17_dim_state.sql` | table `mart.dim_state` (name, region, lat/long) | Page 4 map |
| *(already in `03`)* `review_score` on the fact, `region` on `dim_customer` | columns | Page 3 review visuals, Page 4 region matrix |

> If you built the DB before these edits, either re-run
> `sql/03_star_schema.sql` (rebuilds the fact + dim_customer with
> `review_score` and `region`) **or** run the two small snippets in
> `sql/UPDATES.sql`. Then in Power BI **Home → Get Data → PostgreSQL** →
> add `mart.cohort_retention` and `mart.rfm_segments`, and **Refresh** the
> existing tables to pull in the new columns.

**B. Relationships to add** (Model view):
- `rfm_segments[customer_key]` → `dim_customer[customer_key]`, **1:1**,
  cross-filter **Both**.
- `dim_state[state]` → `dim_customer[state]`, **1:many**, single direction.
*(`cohort_retention` stays standalone — no relationship.)*

**C. Calculated columns to create** (from `measures.dax`, using
**New column**, not New measure): `delivery_bucket` and
`delivery_bucket_sort` on `fact_order_items` — then set `delivery_bucket`'s
**Sort by column** to `delivery_bucket_sort`.

---

> **Report-level filter — do this once for the whole report.** The data
> trails off to a stray 1-order month (Sep 2018) that makes every time
> chart crash to zero at the end. In the Filters pane, drag
> `dim_date[year_month]` to **Filters on all pages** and set it to
> **is on or before 2018-08** (or use `dim_date[date_key]` ≤ 2018-08-31).
> Now every trend line ends cleanly at the last complete month.

### Page 1 — Executive Overview
- **5 cards** (top row): use the **Card** visual (the single-number tile),
  NOT the "KPI" visual. Put one measure in each card's **Fields** well,
  nothing on any axis: `Total Revenue`, `Total Orders`, `AOV`,
  `Total Customers`, `Retention Rate`.
  *(The "KPI" visual needs a Trend axis + Target and will show a single
  month's value instead of the total — that's not what we want here.)*
- **Line chart**: X = `dim_date[year_month]`, Y = `Total Revenue` and
  `Rolling 3-Month Revenue`. Then **"..." → Sort axis → year_month →
  ascending** so months read chronologically.
- **Card**: `MoM Growth (Latest Month)` (format %). *Not* the generic
  `MoM Revenue Growth %` — that reads 0% at the all-months total.
- **Bar chart**: X = `dim_product[category]`, Y = `Total Revenue`; filter
  to **Top 10 by Total Revenue** (visual's filter pane → Top N).

### Page 2 — Customers & Retention
*Prereq: `mart.cohort_retention` + `mart.rfm_segments` imported (see
Prerequisites A/B).*
- **Matrix (the cohort heatmap)** — table `cohort_retention`:
  - **Rows** = `cohort_label`
  - **Columns** = `period_index`
  - **Values** = `retention_pct` → its dropdown → aggregation **Average**
    (each cell is one row, so Average shows the exact value, not a Sum).
  Then **Cell elements → Background color → On** for the heatmap.
  *(Standalone table — no relationship needed.)*
- **Bar/donut — customers & revenue by RFM segment** (table
  `rfm_segments`): Axis/Legend = `segment`; Values = `Count of
  customer_key` (customers) and `Sum of monetary` (revenue).
- **Stacked bar — repeat vs one-time** (table `rfm_segments`): Axis =
  `customer_type`, Values = `Count of customer_key` and `Sum of monetary`.
  (Or a card with the `Retention Rate` measure = 3.0%.)

### Page 3 — Products & Categories
*Prereq: `review_score` on the fact + `delivery_bucket` column (see
Prerequisites A/C).*
- **Bar chart**: X = `dim_product[category]`, Y = `Total Revenue`; Top 15
  by Total Revenue.
- **Column chart (headline)**: X = `fact_order_items[delivery_bucket]`,
  Y = `Avg Review Score`. (delivery_bucket must be sorted by
  `delivery_bucket_sort`.)
- **Bar chart**: X = `dim_product[category]`, Y = `Avg Review Score`; sort
  descending, filter `Count of order_id` ≥ 300 to drop thin categories.
- **Cards**: `On-Time Delivery %`, `Avg Delivery Days`.

### Page 4 — Geography
*Prereq: `region` on `dim_customer` (see Prerequisites A).*
- **Map (use the `Map` bubble visual, from `dim_state`)**: Latitude =
  `dim_state[latitude]`, Longitude = `dim_state[longitude]`, Bubble size =
  `Total Revenue`, Tooltips = `state_name`. Using lat/long places every
  state exactly and avoids the mis-geocoding you get from 2-letter codes
  (PA→USA, MT→Montana, etc.). *(The bare-code "Filled map" is why states
  scattered across the USA/Australia — lat/long fixes it.)*
- **Bar chart**: X = `dim_customer[state]`, Y = `Total Revenue`; Top 10.
- **Matrix**: Rows = `dim_customer[region]`; Values = `Total Orders`,
  `Total Customers`, `Total Revenue`, `AOV`.

### Slicers (add to every page, top or left)
`dim_date[year_month]` (range), `dim_customer[state]`,
`dim_product[category]`. Use **Sync slicers** (View → Sync slicers) so a
filter set on one page follows the user across all four.

### Page gotchas (read if a visual looks wrong)

- **"Avg Review Score by delivery_bucket" is empty** → `review_score` on
  the fact is NULL. Run the `UPDATE` in `sql/UPDATES.sql` to populate it,
  then **Home → Refresh**. (Expected bars: 0-3d 4.39 → 22+d 3.02 →
  Not delivered 1.81.)
- **Cohort matrix cuts off / missing later cohorts** → the visual is too
  short; drag it taller. There are **23** cohort rows (2016-09 → 2018-08).
- **Cohort matrix Totals look weird** (e.g. a 13.5 grand total) → turn OFF
  Row and Column subtotals (Format → Subtotals). Averaging retention
  across periods isn't meaningful; the diagonal is the story.
- **Any card / chart shows blank after adding a SQL column** → do a full
  **Refresh**; just adding the field to a visual won't re-pull the data.

---

## 6. Publish & get the live link  (~5 min)

1. **File → Save** as `powerbi/RetailPulse.pbix`.
2. **Home → Publish** → choose **My workspace** → Publish.
3. In **Power BI Service** (app.powerbi.com), open the report.
4. For a portfolio, make it world-viewable:
   **File → Embed report → Publish to web (public)** → copy the link.
   *(This dataset is public Olist sample data, so there's no privacy
   concern in making it public — note that in the README.)*
5. Paste that link at the **top of `README.md`**.

---

## 7. Screenshots

With the report open in Service (or Desktop, full-screen each page):
capture each page and save as
`assets/dashboard_overview.png`, `assets/dashboard_cohort.png`,
`assets/dashboard_product.png`, `assets/dashboard_geo.png`.
The README already references these filenames.

---

## Checklist

- [ ] 5 tables imported, 4 relationships confirmed, `dim_date` marked
- [ ] All measures from `measures.dax` created and formatted
- [ ] 4 pages built, one consistent theme, 3 synced slicers
- [ ] Published to Service, "Publish to web" link copied
- [ ] Link at top of README, 4 screenshots in `assets/`
