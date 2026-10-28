-- Задание 5. Выручка и доля по каждой категории товаров.
BEGIN;
CREATE SCHEMA IF NOT EXISTS mart;
DROP TABLE IF EXISTS mart.revenue_by_category;

CREATE TABLE mart.revenue_by_category AS
WITH revenue_per_category AS (
    SELECT p.category_id,
           SUM(i.price) AS revenue
    FROM core.order_items i
    JOIN core.orders o ON o.order_id = i.order_id
    JOIN core.products p ON p.product_id = i.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.category_id
),
category_totals AS (
    SELECT c.category_id,
           COALESCE(c.category_name_en, c.category_name_pt, c.category_id) AS category_name,
           COALESCE(r.revenue, 0)::numeric(14,2) AS revenue
    FROM core.categories c
    LEFT JOIN revenue_per_category r ON r.category_id = c.category_id
)
SELECT category_id,
       category_name,
       revenue,
       COALESCE(
           ROUND(100.0 * revenue / NULLIF(SUM(revenue) OVER (), 0), 2),
           0
       ) AS percent_of_total
FROM category_totals
ORDER BY revenue DESC, category_id;
COMMIT;

SELECT * FROM mart.revenue_by_category ORDER BY revenue DESC, category_id;
-- Контроль: 74 категории; крупнейшая = 1 233 131.72;
-- SUM(revenue) = 13 221 498.11.
