-- Задание 2. Топ-10 продавцов по выручке.
BEGIN;
CREATE SCHEMA IF NOT EXISTS mart;
DROP TABLE IF EXISTS mart.top_sellers;

CREATE TABLE mart.top_sellers AS
SELECT s.seller_id,
       s.seller_city,
       s.seller_state,
       COUNT(DISTINCT i.order_id) AS orders_count,
       COUNT(*) AS units_count,
       SUM(i.price)::numeric(14,2) AS revenue
FROM core.order_items i
JOIN core.orders o ON o.order_id = i.order_id
JOIN core.sellers s ON s.seller_id = i.seller_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.seller_city, s.seller_state
ORDER BY revenue DESC, s.seller_id
LIMIT 10;
COMMIT;

SELECT * FROM mart.top_sellers ORDER BY revenue DESC, seller_id;
-- Контроль: выручка первого продавца = 226 987.93.
