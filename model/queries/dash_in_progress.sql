SELECT count(DISTINCT o.order_id)    AS orders_count,
       coalesce(sum(i.price), 0)     AS goods_value
FROM core.orders o
JOIN core.order_status s ON s.order_status = o.order_status AND s.is_in_progress
LEFT JOIN core.order_items i ON i.order_id = o.order_id;
