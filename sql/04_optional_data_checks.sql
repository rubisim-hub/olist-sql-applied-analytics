/* =========================================================
   BASIC ROW COUNTS
   ========================================================= */
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'product_category_translation', COUNT(*) FROM product_category_translation;


/* =========================================================
   NULL CHECKS FOR PRIMARY KEYS / IMPORTANT IDS
   ========================================================= */
SELECT COUNT(*) AS null_customer_ids
FROM customers
WHERE customer_id IS NULL;

SELECT COUNT(*) AS null_order_ids
FROM orders
WHERE order_id IS NULL;

SELECT COUNT(*) AS null_order_item_order_ids
FROM order_items
WHERE order_id IS NULL;

SELECT COUNT(*) AS null_product_ids
FROM order_items
WHERE product_id IS NULL;


/* =========================================================
   DUPLICATE CHECKS
   ========================================================= */
SELECT customer_id, COUNT(*) AS duplicate_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT order_id, COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT order_id, order_item_id, COUNT(*) AS duplicate_count
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;


/* =========================================================
   ORDERS WITHOUT RELATED RECORDS
   ========================================================= */
SELECT COUNT(*) AS orders_without_items
FROM orders o
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;

SELECT COUNT(*) AS orders_without_payments
FROM orders o
LEFT JOIN payments p
    ON o.order_id = p.order_id
WHERE p.order_id IS NULL;

SELECT COUNT(*) AS orders_without_reviews
FROM orders o
LEFT JOIN reviews r
    ON o.order_id = r.order_id
WHERE r.order_id IS NULL;

