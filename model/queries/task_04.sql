WITH per_person AS (
    SELECT c.customer_unique_id,
           count(*) AS orders_count
    FROM core.orders o
    JOIN core.customers c ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT count(*)                                                        AS customers_count,
       count(*) FILTER (WHERE orders_count >= 2)                       AS repeat_customers,
       round(100.0 * count(*) FILTER (WHERE orders_count >= 2) / count(*), 2) AS repeat_share_pct
FROM per_person;
