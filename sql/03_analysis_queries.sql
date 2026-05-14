/* =========================================================
   QUERY 01 — KPI OVERVIEW
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
    ROUND(AVG(order_gmv), 2) AS avg_order_value,
    ROUND(MAX(order_gmv), 2) AS max_order_value
FROM order_totals;


/* =========================================================
   QUERY 02 — MONTHLY REVENUE TREND
   ========================================================= */
WITH order_totals AS (
    SELECT
        oi.order_id,
        SUM(oi.price + oi.freight_value) AS order_gmv
    FROM order_items oi
    GROUP BY oi.order_id
)
SELECT
    strftime('%Y-%m', o.order_purchase_timestamp) AS purchase_month,
    COUNT(DISTINCT o.order_id) AS orders_count,
    ROUND(SUM(ot.order_gmv), 2) AS revenue,
    ROUND(AVG(ot.order_gmv), 2) AS avg_order_value
FROM orders o
JOIN order_totals ot
    ON o.order_id = ot.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY strftime('%Y-%m', o.order_purchase_timestamp)
ORDER BY purchase_month;


/* =========================================================
   QUERY 03 — TOP 10 CUSTOMERS BY REVENUE
   ========================================================= */
SELECT
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
ORDER BY total_revenue DESC
LIMIT 10;


/* =========================================================
   QUERY 04 — REPEAT CUSTOMERS
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
) t;


/* =========================================================
   QUERY 05 — REVENUE BY CATEGORY
   ========================================================= */
SELECT
    COALESCE(pct.product_category_name_english, p.product_category_name) AS category,
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
GROUP BY category
ORDER BY revenue DESC
LIMIT 15;


/* =========================================================
   QUERY 06 — MONTHLY CATEGORY TRENDS
   ========================================================= */
SELECT
    strftime('%Y-%m', o.order_purchase_timestamp) AS purchase_month,
    COALESCE(pct.product_category_name_english, p.product_category_name) AS category,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS revenue
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
LEFT JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pct
    ON p.product_category_name = pct.product_category_name
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY purchase_month, category
HAVING revenue > 0
ORDER BY purchase_month, revenue DESC;


/* =========================================================
   QUERY 07 — TOP SELLERS BY GMV
   ========================================================= */
SELECT
    s.seller_id,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS orders_count,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS gmv
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY s.seller_id, s.seller_state
ORDER BY gmv DESC
LIMIT 10;


/* =========================================================
   QUERY 08 — SELLER CONCENTRATION (TOP 10 SELLERS SHARE)
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
        SELECT gmv
        FROM seller_revenue
        ORDER BY gmv DESC
        LIMIT 10
    )
),
all_sellers AS (
    SELECT SUM(gmv) AS total_gmv
    FROM seller_revenue
)
SELECT
    ROUND(top10.top10_gmv, 2) AS top10_gmv,
    ROUND(all_sellers.total_gmv, 2) AS total_gmv,
    ROUND(100.0 * top10.top10_gmv / all_sellers.total_gmv, 2) AS top10_share_pct
FROM top10, all_sellers;


/* =========================================================
   QUERY 09 — ORDER STATUS DISTRIBUTION
   ========================================================= */
SELECT
    order_status,
    COUNT(*) AS orders_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders), 2) AS share_pct
FROM orders
GROUP BY order_status
ORDER BY orders_count DESC;


/* =========================================================
   QUERY 10 — DELIVERY PERFORMANCE
   ========================================================= */
SELECT
    ROUND(AVG(julianday(order_delivered_customer_date) - julianday(order_purchase_timestamp)), 2) AS avg_delivery_days,
    ROUND(AVG(julianday(order_estimated_delivery_date) - julianday(order_purchase_timestamp)), 2) AS avg_estimated_days,
    ROUND(
        100.0 * AVG(
            CASE
                WHEN julianday(order_delivered_customer_date) > julianday(order_estimated_delivery_date) THEN 1
                ELSE 0
            END
        ), 2
    ) AS late_delivery_rate_pct
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


/* =========================================================
   QUERY 11 — LATE DELIVERY RATE BY CUSTOMER STATE
   ========================================================= */
SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,
    ROUND(
        100.0 * AVG(
            CASE
                WHEN julianday(o.order_delivered_customer_date) > julianday(o.order_estimated_delivery_date) THEN 1
                ELSE 0
            END
        ), 2
    ) AS late_delivery_rate_pct,
    ROUND(AVG(julianday(o.order_delivered_customer_date) - julianday(o.order_purchase_timestamp)), 2) AS avg_delivery_days
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
HAVING delivered_orders >= 100
ORDER BY late_delivery_rate_pct DESC;


/* =========================================================
   QUERY 12 — REVIEW SCORE DISTRIBUTION
   ========================================================= */
SELECT
    review_score,
    COUNT(*) AS review_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM reviews), 2) AS share_pct
FROM reviews
GROUP BY review_score
ORDER BY review_score;


/* =========================================================
   QUERY 13 — LOWEST-RATED CATEGORIES WITH SUFFICIENT VOLUME
   ========================================================= */
SELECT
    COALESCE(pct.product_category_name_english, p.product_category_name) AS category,
    COUNT(DISTINCT r.order_id) AS reviewed_orders,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
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
GROUP BY category
HAVING reviewed_orders >= 100
ORDER BY avg_review_score ASC, reviewed_orders DESC
LIMIT 15;


/* =========================================================
   QUERY 14 — PAYMENT TYPE MIX
   ========================================================= */
SELECT
    payment_type,
    COUNT(*) AS payment_rows,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(AVG(payment_value), 2) AS avg_payment_value
FROM payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;


/* =========================================================
   QUERY 15 — ML-READY ORDER FEATURE PREVIEW
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
SELECT
    o.order_id,
    c.customer_unique_id,
    c.customer_state,
    strftime('%Y-%m', o.order_purchase_timestamp) AS purchase_month,
    ov.order_gmv,
    ov.total_freight,
    ov.items_count,
    ov.sellers_count,
    ps.max_installments,
    r.review_score,
    CASE
        WHEN julianday(o.order_delivered_customer_date) > julianday(o.order_estimated_delivery_date) THEN 1
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
