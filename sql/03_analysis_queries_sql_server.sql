USE olist_sql_project;
GO

/* =========================================================
   OLIST SQL SERVER PORTFOLIO QUERIES
   Author: Reuven (Rubi) Simhayov
   Notes:
   - SQL Server / SSMS compatible version
   - Built for the imported Olist tables
   - If SSMS shows stale red underlines after renaming columns,
     refresh IntelliSense with Ctrl+Shift+R
   ========================================================= */

/* =========================================================
   QUERY 01 — KPI OVERVIEW
   What it shows:
   - total orders
   - gross merchandise value (GMV)
   - average order value
   - max order value
   ========================================================= */
WITH order_totals AS (
    SELECT
        order_id,
        SUM(price + freight_value) AS order_gmv
    FROM order_items
    GROUP BY order_id
)
SELECT
    COUNT(*) AS total_orders,
    ROUND(SUM(order_gmv), 2) AS gross_merchandise_value,
    ROUND(AVG(CAST(order_gmv AS FLOAT)), 2) AS avg_order_value,
    ROUND(MAX(order_gmv), 2) AS max_order_value
FROM order_totals;
GO

/* =========================================================
   QUERY 02 — MONTHLY REVENUE TREND
   What it shows:
   - monthly order volume
   - monthly revenue
   - monthly average order value
   ========================================================= */
WITH order_totals AS (
    SELECT
        oi.order_id,
        SUM(oi.price + oi.freight_value) AS order_gmv
    FROM order_items oi
    GROUP BY oi.order_id
)
SELECT
    CONVERT(char(7), CAST(o.order_purchase_timestamp AS date), 120) AS purchase_month,
    COUNT(DISTINCT o.order_id) AS orders_count,
    ROUND(SUM(ot.order_gmv), 2) AS revenue,
    ROUND(AVG(CAST(ot.order_gmv AS FLOAT)), 2) AS avg_order_value
FROM orders o
JOIN order_totals ot
    ON o.order_id = ot.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY CONVERT(char(7), CAST(o.order_purchase_timestamp AS date), 120)
ORDER BY purchase_month;
GO

/* =========================================================
   QUERY 03 — REVENUE BY CATEGORY
   What it shows:
   - top categories by items sold and revenue
   - uses translated category names when available
   - falls back to 'unknown_category' when category is missing
   ========================================================= */
SELECT TOP 15
    COALESCE(pct.product_category_name_english, p.product_category_name, 'unknown_category') AS category,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS revenue
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
LEFT JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pct
    ON p.product_category_name = pct.product_category_name
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY COALESCE(pct.product_category_name_english, p.product_category_name, 'unknown_category')
ORDER BY revenue DESC;
GO

/* =========================================================
   QUERY 04 — TOP 10 CUSTOMERS BY REVENUE
   What it shows:
   - highest-value customers
   - number of orders per customer
   - total revenue by customer
   ========================================================= */
SELECT TOP 10
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY c.customer_unique_id
ORDER BY total_revenue DESC;
GO

/* =========================================================
   QUERY 05 — REPEAT CUSTOMERS
   What it shows:
   - number of customers with more than one completed order
   ========================================================= */
SELECT
    COUNT(*) AS repeat_customers
FROM (
    SELECT
        c.customer_unique_id
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id
    HAVING COUNT(DISTINCT o.order_id) > 1
) AS repeat_customer_list;
GO

/* =========================================================
   QUERY 06 — ORDER STATUS DISTRIBUTION
   What it shows:
   - how orders are distributed across statuses
   - operational health of the order pipeline
   ========================================================= */
WITH status_counts AS (
    SELECT
        order_status,
        COUNT(*) AS orders_count
    FROM orders
    GROUP BY order_status
)
SELECT
    order_status,
    orders_count,
    ROUND(100.0 * orders_count / SUM(orders_count) OVER (), 2) AS share_pct
FROM status_counts
ORDER BY orders_count DESC;
GO

/* =========================================================
   QUERY 07 — DELIVERY PERFORMANCE
   What it shows:
   - average delivery time
   - average estimated delivery time
   - percentage of late deliveries
   ========================================================= */
SELECT
    ROUND(AVG(CAST(DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date) AS FLOAT)), 2) AS avg_delivery_days,
    ROUND(AVG(CAST(DATEDIFF(day, order_purchase_timestamp, order_estimated_delivery_date) AS FLOAT)), 2) AS avg_estimated_days,
    ROUND(
        100.0 * AVG(
            CASE
                WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1.0
                ELSE 0.0
            END
        ), 2
    ) AS late_delivery_rate_pct
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;
GO

/* =========================================================
   QUERY 08 — LATE DELIVERY RATE BY CUSTOMER STATE
   What it shows:
   - delivery performance by geography
   - highlights states with worse logistics outcomes
   ========================================================= */
SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,
    ROUND(
        100.0 * AVG(
            CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1.0
                ELSE 0.0
            END
        ), 2
    ) AS late_delivery_rate_pct,
    ROUND(AVG(CAST(DATEDIFF(day, o.order_purchase_timestamp, o.order_delivered_customer_date) AS FLOAT)), 2) AS avg_delivery_days
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(*) >= 100
ORDER BY late_delivery_rate_pct DESC;
GO

/* =========================================================
   QUERY 09 — SELLER CONCENTRATION (TOP 10 SELLERS' SHARE)
   What it shows:
   - how much GMV is concentrated among the top 10 sellers
   - useful for marketplace dependency analysis
   ========================================================= */
WITH seller_revenue AS (
    SELECT
        oi.seller_id,
        SUM(oi.price + oi.freight_value) AS gmv
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY oi.seller_id
),
top10 AS (
    SELECT SUM(gmv) AS top10_gmv
    FROM (
        SELECT TOP 10 gmv
        FROM seller_revenue
        ORDER BY gmv DESC
    ) AS top_sellers
),
all_sellers AS (
    SELECT SUM(gmv) AS total_gmv
    FROM seller_revenue
)
SELECT
    ROUND(top10.top10_gmv, 2) AS top10_gmv,
    ROUND(all_sellers.total_gmv, 2) AS total_gmv,
    ROUND(100.0 * top10.top10_gmv / NULLIF(all_sellers.total_gmv, 0), 2) AS top10_share_pct
FROM top10
CROSS JOIN all_sellers;
GO

/* =========================================================
   QUERY 10 — LOWEST-RATED CATEGORIES WITH SUFFICIENT VOLUME
   What it shows:
   - categories with low average review scores
   - filters to categories with enough reviewed orders
   - uses 'unknown_category' for missing category labels
   ========================================================= */
SELECT TOP 15
    COALESCE(pct.product_category_name_english, p.product_category_name, 'unknown_category') AS category,
    COUNT(DISTINCT r.order_id) AS reviewed_orders,
    ROUND(AVG(CAST(r.review_score AS FLOAT)), 2) AS avg_review_score
FROM reviews r
JOIN orders o
    ON r.order_id = o.order_id
JOIN order_items oi
    ON o.order_id = oi.order_id
LEFT JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pct
    ON p.product_category_name = pct.product_category_name
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY COALESCE(pct.product_category_name_english, p.product_category_name, 'unknown_category')
HAVING COUNT(DISTINCT r.order_id) >= 100
ORDER BY avg_review_score ASC, reviewed_orders DESC;
GO

/* =========================================================
   QUERY 11 — PAYMENT TYPE MIX
   What it shows:
   - most common payment types
   - payment value by method
   - average payment value by method
   ========================================================= */
SELECT
    payment_type,
    COUNT(*) AS payment_rows,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(AVG(CAST(payment_value AS FLOAT)), 2) AS avg_payment_value
FROM payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;
GO

/* =========================================================
   QUERY 12 — ML-READY ORDER FEATURE PREVIEW
   What it shows:
   - order-level features that could support ML tasks
   - includes value, freight, item count, seller count,
     payment behavior, review outcome, and delivery delay flags
   Note:
   - TOP 100 is used as a preview; remove it for the full dataset
   ========================================================= */
WITH order_value AS (
    SELECT
        order_id,
        SUM(price + freight_value) AS order_gmv,
        SUM(freight_value) AS total_freight,
        COUNT(*) AS items_count,
        COUNT(DISTINCT seller_id) AS sellers_count
    FROM order_items
    GROUP BY order_id
),
payment_summary AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment_value,
        MAX(payment_installments) AS max_installments
    FROM payments
    GROUP BY order_id
)
SELECT TOP 100
    o.order_id,
    c.customer_unique_id,
    c.customer_state,
    CONVERT(char(7), CAST(o.order_purchase_timestamp AS date), 120) AS purchase_month,
    ov.order_gmv,
    ov.total_freight,
    ov.items_count,
    ov.sellers_count,
    ps.total_payment_value,
    ps.max_installments,
    r.review_score,
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1
        ELSE 0
    END AS late_delivery_flag,
    CASE
        WHEN r.review_score <= 2 THEN 1
        ELSE 0
    END AS low_review_flag
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
LEFT JOIN order_value ov
    ON o.order_id = ov.order_id
LEFT JOIN payment_summary ps
    ON o.order_id = ps.order_id
LEFT JOIN reviews r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered';
GO
