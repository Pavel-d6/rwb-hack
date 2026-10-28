INSERT INTO core.orders (order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at,
                         order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date)
SELECT NULLIF(trim(order_id), ''),
       NULLIF(trim(customer_id), ''),
       NULLIF(trim(order_status), ''),
       NULLIF(trim(order_purchase_timestamp), '')::timestamp,
       NULLIF(trim(order_approved_at), '')::timestamp,
       NULLIF(trim(order_delivered_carrier_date), '')::timestamp,
       NULLIF(trim(order_delivered_customer_date), '')::timestamp,
       NULLIF(trim(order_estimated_delivery_date), '')::timestamp
FROM raw.orders;

INSERT INTO core.order_items (order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value)
SELECT NULLIF(trim(order_id), ''),
       NULLIF(trim(order_item_id), '')::integer,
       NULLIF(trim(product_id), ''),
       NULLIF(trim(seller_id), ''),
       NULLIF(trim(shipping_limit_date), '')::timestamp,
       NULLIF(trim(price), '')::numeric(12,2),
       NULLIF(trim(freight_value), '')::numeric(12,2)
FROM raw.order_items;

INSERT INTO core.payments (order_id, payment_sequential, payment_type, payment_installments, payment_value)
SELECT NULLIF(trim(order_id), ''),
       NULLIF(trim(payment_sequential), '')::integer,
       NULLIF(trim(payment_type), ''),
       NULLIF(trim(payment_installments), '')::integer,
       NULLIF(trim(payment_value), '')::numeric(12,2)
FROM raw.order_payments;

INSERT INTO core.reviews (review_id, order_id, review_score, review_comment_title, review_comment_message,
                          review_creation_date, review_answer_timestamp)
SELECT NULLIF(trim(review_id), ''),
       NULLIF(trim(order_id), ''),
       NULLIF(trim(review_score), '')::smallint,
       NULLIF(trim(review_comment_title), ''),
       NULLIF(trim(review_comment_message), ''),
       NULLIF(trim(review_creation_date), '')::timestamp,
       NULLIF(trim(review_answer_timestamp), '')::timestamp
FROM raw.order_reviews;
