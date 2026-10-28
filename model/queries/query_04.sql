-- Задание 4. Уникальные покупатели и повторные покупки.
BEGIN;
CREATE SCHEMA IF NOT EXISTS mart;
DROP TABLE IF EXISTS mart.repeat_customers;

CREATE TABLE mart.repeat_customers AS
WITH orders_per_person AS (
    SELECT c.customer_unique_id,
           COUNT(DISTINCT o.order_id) AS orders_count
    FROM core.customers c
    JOIN core.orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)
SELECT COUNT(*) AS total_customers,
       COUNT(*) FILTER (WHERE orders_count >= 2) AS repeat_customers,
       ROUND(
           100.0 * COUNT(*) FILTER (WHERE orders_count >= 2)
           / NULLIF(COUNT(*), 0),
           2
       ) AS repeat_rate_percent
FROM orders_per_person;
COMMIT;

SELECT * FROM mart.repeat_customers;
-- Контроль: total_customers = 96 096; repeat_rate_percent = 3.12.
