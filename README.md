# Retail Sales & Customer Analytics

SQL and Power BI project built on real transaction data from a UK-based online gift shop. Uses the UCI "Online Retail II" dataset, covering Dec 2009 to Dec 2011. Source: https://archive.ics.uci.edu/dataset/502/online+retail+ii, free to download, no login needed.

## The dataset

After cleaning: 1,027,017 line items across 40,077 orders, 5,878 identified customers, spread across 43 countries.

## What's in this repo

- `README.md` - this file
- `BUILD_GUIDE.md` - how the Power BI dashboard was built, step by step
- `analysis.sql` - the 7 SQL queries behind the findings below
- `orders.csv` - one row per order: customer, country, date, revenue, cancelled flag
- `products.csv` - product catalog with average price, units sold, and revenue
- `customers.csv` - one row per customer: country, first order date, last order date
- `Retail Sales Analytics Dashboard.pbix` - the finished Power BI file, open it directly in Power BI Desktop
- `dashboard_screenshot.png` - a preview if you don't have Power BI installed

The full raw line-item file (over 1M rows) isn't included here since it's too large for a normal GitHub upload. The three CSVs above cover the same data in a lighter format. Grab the original file straight from UCI if you want to rebuild everything from scratch.

## How the data was cleaned

- Dropped rows with a missing product description, a price of zero or less, or a quantity of zero
- Removed 34,147 exact duplicate rows
- Flagged cancelled orders instead of deleting them (invoice numbers starting with "C"), 19,494 cancelled line items total, kept so the cancellation rate could actually be measured
- Filtered out postage, manual entry, and bank charge codes before doing any product-level analysis
- About 229K rows had no customer ID, likely guest checkouts. Kept those for revenue totals, left them out of customer-level metrics like repeat rate and RFM

## Findings

These come from the live DAX measures in the dashboard, which is the authoritative source.

- Net revenue: $19.0M over the two-year window, with a clear spike every November. (An early SQL-only pass came out to $20.48M because it excluded cancelled invoices outright instead of netting the returns against gross sales. $19.0M is the accurate figure.)
- UK customers account for about 85% of revenue. Ireland, Netherlands, and Germany trail well behind.
- Best sellers are the Regency Cakestand 3 Tier ($330,590) and the White Hanging Heart T-Light Holder ($260,990).
- 71.7% of identified customers ordered more than once.
- The top 20% of customers by spend account for 77.3% of total revenue.
- 17.1% of orders get cancelled. Looking at individual line items instead, that rate drops to 1.86% ($1.46M in reversed revenue), since a cancelled invoice usually only has a few items on it. The order-level number is the more useful one to lead with.

## Recommendation

A small slice of customers is doing most of the work here. Putting budget into retention and loyalty for that top 20% is probably a better return than spending it on broad customer acquisition.

## The dashboard

`Retail Sales Analytics Dashboard.pbix` is a finished, working dashboard: 4 KPI cards, a monthly revenue trend, revenue by country, top customers, and top products, all wired to live DAX measures. Open it in Power BI Desktop to explore it. Check `BUILD_GUIDE.md` if you want to see how it was put together or rebuild it yourself.
