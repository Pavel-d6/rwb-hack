-- Задание 3. Средний чек, среднее число логических строк и единиц товара.
BEGIN;
CREATE SCHEMA IF NOT EXISTS mart;
DROP TABLE IF EXISTS mart.avg_check;

CREATE TABLE mart.avg_check AS
WITH per_order AS (
    SELECT i.order_id,
           SUM(i.price + i.freight_value) AS order_total,
           COUNT(DISTINCT (i.product_id, i.seller_id)) AS lines_count,
           COUNT(*) AS units_count
    FROM core.order_items i
    JOIN core.orders o ON o.order_id = i.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY i.order_id
)
SELECT COUNT(*) AS orders_count,
       ROUND(AVG(order_total), 2) AS avg_check,
       ROUND(AVG(lines_count), 4) AS avg_lines_per_order,
       ROUND(AVG(units_count), 4) AS avg_units_per_order
FROM per_order;
COMMIT;

SELECT * FROM mart.avg_check;
-- Контроль: avg_check = 159.88.
