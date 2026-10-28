WITH per_order AS (
    SELECT i.order_id,
           sum(i.price + i.freight_value)                 AS order_total,
           sum(i.price)                                   AS goods_total,
           count(DISTINCT (i.product_id, i.seller_id))    AS lines_count,
           count(*)                                       AS units_count
    FROM core.order_items i
    JOIN core.orders       o  ON o.order_id = i.order_id
    JOIN core.order_status st ON st.order_status = o.order_status AND st.is_revenue
    GROUP BY i.order_id
)
SELECT count(*)                           AS orders_count,
       round(avg(order_total), 2)         AS avg_check,
       round(avg(goods_total), 2)         AS avg_goods_revenue_per_order,
       round(avg(lines_count), 4)         AS avg_lines_per_order,
       round(avg(units_count), 4)         AS avg_units_per_order
FROM per_order;
