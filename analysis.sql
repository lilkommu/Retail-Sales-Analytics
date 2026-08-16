-- ============================================================
-- Retail Sales & Customer Analytics — Real Data (UCI Online Retail II)
-- Table: retail(invoice, stock_code, description, quantity, invoice_date,
--               price, customer_id, country, is_cancelled, revenue, has_customer_id)
-- Source: UCI Online Retail II (Dec 2009 - Dec 2011, UK-based online gift retailer)
-- ============================================================

-- 1. Monthly revenue trend (excluding cancelled invoices)
SELECT strftime('%Y-%m', invoice_date) AS month,
       ROUND(SUM(revenue), 2) AS monthly_revenue,
       COUNT(DISTINCT invoice) AS orders
FROM retail
WHERE is_cancelled = 0
GROUP BY month
ORDER BY month;

-- 2. Revenue by country
SELECT country, ROUND(SUM(revenue), 2) AS revenue, COUNT(DISTINCT invoice) AS orders
FROM retail
WHERE is_cancelled = 0
GROUP BY country
ORDER BY revenue DESC
LIMIT 10;

-- 3. Top 15 products by revenue (excludes non-product adjustment codes: POST, DOT, M/m = postage/manual/bank-charge entries)
SELECT description, ROUND(SUM(revenue), 2) AS revenue, SUM(quantity) AS units_sold
FROM retail
WHERE is_cancelled = 0
  AND UPPER(stock_code) NOT IN ('POST','DOT','M','BANK CHARGES','C2','CRUK','PADS','AMAZONFEE','ADJUST','ADJUST2')
GROUP BY description
ORDER BY revenue DESC
LIMIT 15;

-- 4. Repeat-purchase rate (customers with known ID only)
WITH order_counts AS (
    SELECT customer_id, COUNT(DISTINCT invoice) AS n_orders
    FROM retail
    WHERE has_customer_id = 1 AND is_cancelled = 0
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN n_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN n_orders > 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS repeat_rate_pct
FROM order_counts;

-- 5. Cancellation / return rate: % of line items and % of gross revenue cancelled
SELECT
    ROUND(100.0 * SUM(CASE WHEN is_cancelled = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_line_items_cancelled,
    ROUND(SUM(CASE WHEN is_cancelled = 1 THEN ABS(revenue) ELSE 0 END), 2) AS cancelled_value
FROM retail;

-- 6. Customer concentration (Pareto): revenue share of top 20% customers by spend
WITH cust_rev AS (
    SELECT customer_id, SUM(revenue) AS total_rev
    FROM retail
    WHERE has_customer_id = 1 AND is_cancelled = 0
    GROUP BY customer_id
),
ranked AS (
    SELECT customer_id, total_rev,
           NTILE(5) OVER (ORDER BY total_rev DESC) AS quintile
    FROM cust_rev
)
SELECT quintile, ROUND(SUM(total_rev), 2) AS revenue,
       ROUND(100.0 * SUM(total_rev) / (SELECT SUM(total_rev) FROM cust_rev), 2) AS pct_of_total
FROM ranked
GROUP BY quintile
ORDER BY quintile;

-- 7. RFM inputs — top 20 customers by monetary value
WITH last_date AS (SELECT MAX(invoice_date) AS max_date FROM retail),
     cust AS (
        SELECT customer_id,
               julianday((SELECT max_date FROM last_date)) - julianday(MAX(invoice_date)) AS recency_days,
               COUNT(DISTINCT invoice) AS frequency,
               ROUND(SUM(revenue), 2) AS monetary
        FROM retail
        WHERE has_customer_id = 1 AND is_cancelled = 0
        GROUP BY customer_id
     )
SELECT * FROM cust ORDER BY monetary DESC LIMIT 20;
