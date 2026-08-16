# Build Guide: Retail Sales & Customer Analytics Dashboard (Real Data)

**Note: this dashboard is already built.** `Retail Sales Analytics Dashboard.pbix` in this folder is a finished, working file — open it directly in Power BI Desktop. The guide below documents how it was built (and the numbers below are the verified, live DAX results — they differ slightly from `analysis.sql`'s raw SQL output, see the note on Cancellation Rate in Step 4). Use this guide if you want to understand the build, extend it, or rebuild it from scratch.

Everything you need to go from the files in this folder to a finished Power BI dashboard and a portfolio-ready GitHub project, using the real UCI "Online Retail II" dataset. Budget 1–2 hours total.

## What you already have

- `cleaned_retail_data.csv` — one row per order line item (real transactions, ~108MB). This is the main file for Power BI.
- `orders.csv`, `customers.csv`, `products.csv` — smaller derived tables if you want a proper data model instead of one flat file (recommended given the flat file's size — see Step 3b).
- `analysis.sql` — the SQL queries behind the findings in `README.md`.
- `README.md` — findings summary and data-cleaning notes.

## Step 1 — Install Power BI Desktop (free, ~10 min)

1. https://www.microsoft.com/en-us/power-platform/products/power-bi/downloads → Download free.
2. Open it. No Microsoft 365 subscription or paid account needed for local use; skip any sign-in prompt.

## Step 2 — Import the data (~5–10 min)

Because `cleaned_retail_data.csv` is large (~1M rows, ~108MB), prefer the star-schema approach (Step 3b) over loading the flat file alone — Power BI handles it fine, but import will take a few minutes.

1. **Home** → **Get Data** → **Text/CSV** → select `cleaned_retail_data.csv` → **Transform Data**.
2. In Power Query Editor, check types:
   - `order_date`/`invoice_date` → Date/Time (should auto-detect)
   - `revenue`, `price` → Decimal Number
   - `quantity` → Whole Number
   - `is_cancelled`, `has_customer_id` → these load as True/False; leave as-is, DAX handles booleans directly
3. **Close & Apply**.

## Step 3a — Quick path: flat table only

Works fine for a first pass — skip to Step 4. Import speed and dashboard responsiveness will be a bit slower than the star schema given the row count.

## Step 3b — Recommended path: star schema (faster, and shows real data-modeling skill)

1. Get Data → Text/CSV for `orders.csv`, `customers.csv`, `products.csv` as well.
2. **Model** view → build relationships:
   - `orders[customer_id]` → `customers[customer_id]` (many-to-one)
   - `cleaned_retail_data[product_id]` → `products[product_id]` (many-to-one)
   - `cleaned_retail_data[order_id]` → `orders[order_id]` (many-to-one)
3. Treat `customers` and `products` as dimension tables, `orders` as a lighter aggregate fact table for KPI cards, and `cleaned_retail_data` as the detail fact table for drill-down visuals.

## Step 4 — Add DAX measures (~15 min)

Right-click the table in **Fields** → **New Measure**:

```dax
Total Revenue = SUM(cleaned_retail_data[revenue])
```

```dax
Total Orders = DISTINCTCOUNT(cleaned_retail_data[order_id])
```

```dax
Total Customers = DISTINCTCOUNT(cleaned_retail_data[customer_id])
```

```dax
Avg Order Value = DIVIDE([Total Revenue], [Total Orders])
```

**Cancellation rate** (line-item basis):

```dax
Cancellation Rate % =
DIVIDE(
    CALCULATE(COUNTROWS(cleaned_retail_data), cleaned_retail_data[is_cancelled] = TRUE),
    COUNTROWS(cleaned_retail_data)
) * 100
```

**Repeat-purchase rate:**

```dax
Repeat Customers =
VAR CustomerOrderCounts =
    SUMMARIZE(
        FILTER(cleaned_retail_data, cleaned_retail_data[has_customer_id] = TRUE && cleaned_retail_data[is_cancelled] = FALSE),
        cleaned_retail_data[customer_id],
        "OrderCount", DISTINCTCOUNT(cleaned_retail_data[order_id])
    )
RETURN
    COUNTROWS(FILTER(CustomerOrderCounts, [OrderCount] > 1))
```

```dax
Repeat Rate % = DIVIDE([Repeat Customers], [Total Customers]) * 100
```

Test each on a blank **Card** visual — you should see values close to the README findings (~$20.5M revenue, ~72% repeat rate, ~1.9% cancellation rate).

## Step 5 — Build the visuals (~30 min)

New report page, "Overview":

1. **KPI cards** (top row): `Total Revenue`, `Total Orders`, `Repeat Rate %`, `Cancellation Rate %`.
2. **Line chart** — "Revenue Trend": X = `invoice_date` (Month level), Y = `Total Revenue`. Should show the Nov 2010 holiday spike.
3. **Bar chart** — "Revenue by Country": Axis = `country`, Value = `Total Revenue` — expect UK to dominate heavily (~85%), so consider a second version filtered to exclude UK to show the rest of the geographic spread.
4. **Bar/table** — "Top 15 Products": Axis = `description`, Value = `Total Revenue` (use the `products.csv` table if on the star schema).
5. **Bar chart — the headline insight** — "Revenue Concentration by Customer Quintile": you'll need to replicate the Pareto query from `analysis.sql` (query 6) as a calculated table or column ranking customers into quintiles by spend, then chart quintile vs. % of total revenue. This is the chart that shows the top 20% of customers drive 77% of revenue.
6. **Table** — "Top 20 Customers": customer_id, frequency, monetary — straight from the RFM query, good for a "who are our best customers" view.

## Step 6 — Add interactivity (~5 min)

Add **Slicers** for `country` and date range near the top. Click through to confirm cross-filtering works across all visuals.

## Step 7 — Polish (~10 min)

- Pick a consistent theme/accent color (View ribbon).
- Title: "Retail Sales & Customer Analytics — UK Online Gift Retailer, 2009–2011".
- Align visuals to a clean grid.
- Format currency ($) on revenue fields, percentage format on rate measures.

## Step 8 — Export for your portfolio

- **File → Export → Export to PDF** (no account needed).
- Or screenshot the finished dashboard (Win+Shift+S) for resume/LinkedIn/GitHub.
- Optional: **File → Publish** for a live link (needs a free Power BI account, separate from Desktop itself).

## Step 9 — Put it on GitHub

1. New public repo, e.g. `retail-sales-analytics`.
2. Upload `analysis.sql`, `orders.csv`, `products.csv`, `customers.csv` (all small), 2–3 dashboard screenshots. Skip uploading the 108MB flat file directly — see the GitHub note in `README.md`.
3. README structure: business question → data & method → findings (from `README.md` here) → recommendation.
4. Link the repo from your resume under the project title.

## Troubleshooting

- **Slow import**: the flat file is ~1M rows; if Power BI feels sluggish, switch to the star-schema tables (`orders.csv`/`products.csv`/`customers.csv`) for your main visuals and only reference `cleaned_retail_data.csv` where line-item detail is truly needed.
- **Repeat Rate % or Cancellation Rate % look off after filtering**: expected — measures recalculate within the current filter context (e.g., filtering to one country changes the rate to that country's rate).
- **UK dominates every chart and hides other countries**: add a slicer to exclude UK, or use a "Top N excluding UK" filter on the country visual so the international breakdown is visible.
- **Date hierarchy shows every day instead of months**: click the field dropdown on the axis and select the Month level, or turn off auto date/time drill.
