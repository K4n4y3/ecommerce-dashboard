-- ============================================================
-- SQL-запросы для дашборда Brazilian E-Commerce
-- Запускай в pgAdmin Query Tool (база: ecommerce)
-- ============================================================


-- ============================================================
-- 1. ВЫРУЧКА ПО МЕСЯЦАМ
-- Используется: Line chart — динамика продаж
-- ============================================================
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    COUNT(DISTINCT o.order_id)                       AS orders_count,
    ROUND(SUM(oi.price + oi.freight_value)::numeric, 2) AS total_revenue,
    ROUND(AVG(oi.price + oi.freight_value)::numeric, 2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2017-01-01'
GROUP BY 1
ORDER BY 1;


-- ============================================================
-- 2. ТОП-10 КАТЕГОРИЙ ПО ВЫРУЧКЕ
-- Используется: Bar chart — какие категории приносят больше всего
-- ============================================================
SELECT
    COALESCE(t.product_category_name_english,
             p.product_category_name, 'unknown')     AS category,
    COUNT(DISTINCT oi.order_id)                       AS orders_count,
    ROUND(SUM(oi.price)::numeric, 0)                 AS revenue,
    ROUND(AVG(oi.price)::numeric, 2)                 AS avg_price
FROM order_items oi
JOIN products p     ON oi.product_id = p.product_id
LEFT JOIN product_category_translation t
       ON p.product_category_name = t.product_category_name
JOIN orders o       ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY revenue DESC
LIMIT 10;


-- ============================================================
-- 3. ВЫРУЧКА И ЗАКАЗЫ ПО ШТАТАМ БРАЗИЛИИ
-- Используется: Map / Table — географический анализ
-- ============================================================
SELECT
    c.customer_state                                  AS state,
    COUNT(DISTINCT o.order_id)                        AS orders_count,
    COUNT(DISTINCT c.customer_unique_id)              AS unique_customers,
    ROUND(SUM(oi.price + oi.freight_value)::numeric, 0) AS total_revenue,
    ROUND(AVG(oi.price + oi.freight_value)::numeric, 2)  AS avg_order_value
FROM orders o
JOIN customers c    ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY total_revenue DESC;


-- ============================================================
-- 4. СРЕДНЕЕ ВРЕМЯ ДОСТАВКИ ПО ШТАТАМ
-- Используется: Bar chart — где доставка быстрее/медленнее
-- ============================================================
SELECT
    c.customer_state                                   AS state,
    COUNT(o.order_id)                                  AS orders_count,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (
            o.order_delivered_customer_date - o.order_purchase_timestamp
        )) / 86400
    )::numeric, 1)                                     AS avg_delivery_days,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (
            o.order_estimated_delivery_date - o.order_delivered_customer_date
        )) / 86400
    )::numeric, 1)                                     AS avg_days_before_estimate
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY 1
HAVING COUNT(o.order_id) >= 50   -- только штаты с достаточной выборкой
ORDER BY avg_delivery_days;


-- ============================================================
-- 5. РАСПРЕДЕЛЕНИЕ ОЦЕНОК ПОКУПАТЕЛЕЙ
-- Используется: Pie / Bar chart — удовлетворённость клиентов
-- ============================================================
SELECT
    r.review_score,
    COUNT(*)                                           AS reviews_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS percentage
FROM order_reviews r
JOIN orders o ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY 1;


-- ============================================================
-- 6. СПОСОБЫ ОПЛАТЫ
-- Используется: Pie chart — популярность payment_type
-- ============================================================
SELECT
    payment_type,
    COUNT(DISTINCT order_id)                           AS orders_count,
    ROUND(SUM(payment_value)::numeric, 0)             AS total_value,
    ROUND(COUNT(DISTINCT order_id) * 100.0 /
          SUM(COUNT(DISTINCT order_id)) OVER (), 1)   AS percentage
FROM order_payments
GROUP BY 1
ORDER BY orders_count DESC;

