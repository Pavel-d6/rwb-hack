-- Задание 1. Число заказов и выручка по месяцам: 2016-09 — 2018-08.
BEGIN;
CREATE SCHEMA IF NOT EXISTS mart;
DROP TABLE IF EXISTS mart.revenue_by_month;

CREATE TABLE mart.revenue_by_month AS
WITH calendar AS (
    SELECT generate_series(
        DATE '2016-09-01', DATE '2018-08-01', INTERVAL '1 month'
    )::date AS month_start
),
monthly_orders AS (
    SELECT date_trunc('month', order_purchase_timestamp)::date AS month_start,
           COUNT(*) AS orders_count
    FROM core.orders
    GROUP BY 1
),
monthly_revenue AS (
    SELECT date_trunc('month', o.order_purchase_timestamp)::date AS month_start,
           SUM(i.price) AS revenue
    FROM core.orders o
    JOIN core.order_items i ON i.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT to_char(c.month_start, 'YYYY-MM') AS month,
       COALESCE(mo.orders_count, 0) AS orders_count,
       COALESCE(mr.revenue, 0)::numeric(14,2) AS revenue
FROM calendar c
LEFT JOIN monthly_orders mo USING (month_start)
LEFT JOIN monthly_revenue mr USING (month_start)
ORDER BY c.month_start;
COMMIT;

SELECT * FROM mart.revenue_by_month ORDER BY month;
-- Контроль: 24 месяца; SUM(revenue) = 13 221 498.11.
