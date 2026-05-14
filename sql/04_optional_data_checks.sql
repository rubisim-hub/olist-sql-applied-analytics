```sql
-- Row counts
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
SELECT 'sellers', COUNT(*) FROM sellers;

-- Null checks for key columns
SELECT COUNT(*) AS null_customer_ids
FROM customers
WHERE customer_id IS NULL;

SELECT COUNT(*) AS null_order_ids
FROM orders
WHERE order_id IS NULL;

SELECT COUNT(*) AS null_product_ids
FROM order_items
WHERE product_id IS NULL;

-- Duplicate checks
SELECT customer_id, COUNT(*)
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT order_id, order_item_id, COUNT(*)
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;
