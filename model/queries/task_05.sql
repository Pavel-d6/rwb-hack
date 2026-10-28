WITH revenue_by_category AS (
    SELECT p.category_id,
           sum(i.price) AS revenue
    FROM core.order_items i
    JOIN core.orders       o  ON o.order_id = i.order_id
    JOIN core.order_status st ON st.order_status = o.order_status AND st.is_revenue
    JOIN core.products     p  ON p.product_id = i.product_id
    GROUP BY p.category_id
)
SELECT c.category_id,
       coalesce(c.category_name_en, c.category_name_pt, c.category_id)        AS category,
       coalesce(r.revenue, 0)                                                 AS revenue,
       round(100.0 * coalesce(r.revenue, 0) / sum(coalesce(r.revenue, 0)) OVER (), 2) AS share_pct
FROM core.categories c
LEFT JOIN revenue_by_category r USING (category_id)
ORDER BY revenue DESC, c.category_id;
