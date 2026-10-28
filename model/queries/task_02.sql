SELECT s.seller_id,
       s.seller_city,
       s.seller_state,
       count(DISTINCT i.order_id) AS orders_count,
       count(*)                   AS units_count,
       sum(i.price)               AS revenue
FROM core.order_items i
JOIN core.orders       o  ON o.order_id = i.order_id
JOIN core.order_status st ON st.order_status = o.order_status AND st.is_revenue
JOIN core.sellers      s  ON s.seller_id = i.seller_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
ORDER BY revenue DESC, s.seller_id
LIMIT 10;
