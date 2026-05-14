DROP VIEW IF EXISTS vw_order_line_enriched;

CREATE VIEW vw_order_line_enriched AS
WITH payment_summary AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment_value,
        MAX(payment_installments) AS max_payment_installments,
        GROUP_CONCAT(DISTINCT payment_type) AS payment_types
    FROM payments
    GROUP BY order_id
)
SELECT
    o.order_id,
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value,
    p.product_category_name,
    pct.product_category_name_english,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    s.seller_city,
    s.seller_state,
    ps.total_payment_value,
    ps.max_payment_installments,
    ps.payment_types,
    r.review_score
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN customers c
    ON o.customer_id = c.customer_id
LEFT JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pct
    ON p.product_category_name = pct.product_category_name
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id
LEFT JOIN payment_summary ps
    ON oi.order_id = ps.order_id
LEFT JOIN reviews r
    ON oi.order_id = r.order_id;
