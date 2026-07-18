# Run RetailPulse on Windows — quickstart

## Your connection details (default PostgreSQL install)

| Field | Value |
|-------|-------|
| Host / Server | `localhost` |
| Port | `5432` |
| Username | `postgres` |
| Password | *(the one you set during install)* |
| Database (to create) | `retailpulse` |

---

## Step 1 — Get the data (~2 min)

Download the 9 CSVs from Kaggle and unzip them into
`data/raw/` (exact filenames in `data/README.md`):
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

---

## Step 2 — Open psql

Start menu → search **"SQL Shell (psql)"** → open it. Press **Enter** to
accept each default, then type your password:

```
Server [localhost]:      (Enter)
Database [postgres]:     (Enter)
Port [5432]:             (Enter)
Username [postgres]:     (Enter)
Password for user postgres:  ******   (type it, Enter)
```

You should see the prompt: `postgres=#`

---

## Step 3 — Create the database

```sql
CREATE DATABASE retailpulse;
\c retailpulse
```

The prompt changes to `retailpulse=#`. You're now inside the new database.

---

## Step 4 — Build everything (run 5 files in order)

Paste these one at a time (note: forward slashes, and `\i` needs the full
path — spaces are fine, no quotes):

```
\i C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/sql/00_schema.sql
\i C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/sql/01_load_windows.sql
\i C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/sql/02_clean.sql
\i C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/sql/03_star_schema.sql
```

After `01_load_windows.sql` you should see the row-count check
(customers 99,441 · orders 99,441 · order_items 112,650 …). After
`03` you should see ~98,199 orders / R$15.7M revenue / AOV ~160.

> Use `01_load_windows.sql` (not `01_load.sql`) — it has your absolute
> paths baked in. If your repo isn't at the path above, edit the paths
> inside that file first.

---

## Step 5 — Run the analysis (optional, to see the numbers)

```
\i C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/sql/10_kpis.sql
\i C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/sql/11_cohort_retention.sql
\i C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/sql/12_rfm_segmentation.sql
\i C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/sql/13_product_category.sql
\i C:/Users/Araj7/Desktop/Research Assistant/RetailPulse/sql/14_geography.sql
```

---

## Step 6 — Connect Power BI

1. Power BI Desktop → **Home → Get Data → PostgreSQL database**.
2. Server `localhost`  ·  Database `retailpulse`  ·  **Import**.
3. If asked to sign in: pick **Database**, user `postgres`, your password.
4. In Navigator tick `mart.fact_order_items`, `mart.dim_date`,
   `mart.dim_customer`, `mart.dim_product`, `mart.dim_seller` → **Load**.
5. Continue in `powerbi/BUILD_GUIDE.md` (model → measures → 4 pages →
   publish).

---

## Troubleshooting

- **"psql not recognized" in a normal terminal** → use the **SQL Shell
  (psql)** app from the Start menu instead; it's pre-configured.
- **`\copy` "could not open file"** → the CSV isn't in `data/raw/` or the
  path in `01_load_windows.sql` doesn't match where the repo lives.
- **Password fails** → it's the password you set during PostgreSQL setup
  for the `postgres` user (not your Windows password).
- **Power BI "Npgsql" prompt** → click to install it, then reconnect.
- **Prefer clicking to typing?** pgAdmin 4 (installed with PostgreSQL)
  does Steps 3–5 in a GUI: right-click Databases → Create → Database
  `retailpulse`, then open the Query Tool and run each file. *(But loading
  via `\copy` is easiest in psql — pgAdmin's server-side COPY can hit file
  permission errors on the Desktop folder.)*
```
