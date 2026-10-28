WITH months AS (
    SELECT generate_series(date '2016-09-01', date '2018-08-01', interval '1 month')::date AS month_start
),
orders_by_month AS (
    SELECT date_trunc('month', o.order_purchase_timestamp)::date AS month_start,
           count(*)                                              AS orders_count,
           count(*) FILTER (WHERE s.is_revenue)                  AS delivered_orders_count
    FROM core.orders o
    JOIN core.order_status s ON s.order_status = o.order_status
    GROUP BY 1
),
revenue_by_month AS (
    SELECT date_trunc('month', o.order_purchase_timestamp)::date AS month_start,
           sum(i.price)                                          AS revenue
    FROM core.order_items i
    JOIN core.orders       o ON o.order_id = i.order_id
    JOIN core.order_status s ON s.order_status = o.order_status
    WHERE s.is_revenue
    GROUP BY 1
)
SELECT to_char(m.month_start, 'YYYY-MM')           AS month,
       coalesce(om.orders_count, 0)                AS orders_count,
       coalesce(om.delivered_orders_count, 0)      AS delivered_orders_count,
       coalesce(rm.revenue, 0)::numeric(14,2)      AS revenue
FROM months m
LEFT JOIN orders_by_month om USING (month_start)
LEFT JOIN revenue_by_month rm USING (month_start)
ORDER BY m.month_start;
