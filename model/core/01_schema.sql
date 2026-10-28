
DROP SCHEMA IF EXISTS core CASCADE;
CREATE SCHEMA core;

CREATE TABLE core.customers (
    customer_id              TEXT PRIMARY KEY,
    customer_unique_id       TEXT NOT NULL,
    customer_zip_code_prefix TEXT,
    customer_city            TEXT,
    customer_state           TEXT
);

CREATE TABLE core.sellers (
    seller_id              TEXT PRIMARY KEY,
    seller_zip_code_prefix TEXT,
    seller_city            TEXT,
    seller_state           TEXT
);

CREATE TABLE core.categories (
    category_id      TEXT PRIMARY KEY,
    category_name_pt TEXT UNIQUE,
    category_name_en TEXT
);

CREATE TABLE core.products (
    product_id                 TEXT PRIMARY KEY,
    category_id                TEXT NOT NULL REFERENCES core.categories (category_id),
    product_name_length        INTEGER CHECK (product_name_length >= 0),
    product_description_length INTEGER CHECK (product_description_length >= 0),
    product_photos_qty         INTEGER CHECK (product_photos_qty >= 0),
    product_weight_g           NUMERIC(12,2) CHECK (product_weight_g >= 0),
    product_length_cm          NUMERIC(12,2) CHECK (product_length_cm >= 0),
    product_height_cm          NUMERIC(12,2) CHECK (product_height_cm >= 0),
    product_width_cm           NUMERIC(12,2) CHECK (product_width_cm >= 0)
);

CREATE TABLE core.orders (
    order_id                      TEXT PRIMARY KEY,
    customer_id                   TEXT NOT NULL REFERENCES core.customers (customer_id),
    order_status                  TEXT NOT NULL,
    order_purchase_timestamp      TIMESTAMP NOT NULL,
    order_approved_at             TIMESTAMP,
    order_delivered_carrier_date  TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP NOT NULL
);

CREATE TABLE core.order_items (
    order_id            TEXT NOT NULL REFERENCES core.orders (order_id),
    order_item_id       INTEGER NOT NULL,
    product_id          TEXT NOT NULL REFERENCES core.products (product_id),
    seller_id           TEXT NOT NULL REFERENCES core.sellers (seller_id),
    shipping_limit_date TIMESTAMP,
    price               NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    freight_value       NUMERIC(12,2) NOT NULL CHECK (freight_value >= 0),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE core.payments (
    order_id             TEXT NOT NULL REFERENCES core.orders (order_id),
    payment_sequential   INTEGER NOT NULL,
    payment_type         TEXT NOT NULL,
    payment_installments INTEGER CHECK (payment_installments >= 0),
    payment_value        NUMERIC(12,2) NOT NULL CHECK (payment_value >= 0),
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE core.reviews (
    review_id               TEXT NOT NULL,
    order_id                TEXT NOT NULL REFERENCES core.orders (order_id),
    review_score            SMALLINT NOT NULL CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    PRIMARY KEY (review_id, order_id)
);

CREATE INDEX idx_customers_unique_id ON core.customers (customer_unique_id);
CREATE INDEX idx_orders_customer_id ON core.orders (customer_id);
CREATE INDEX idx_orders_status_purchase ON core.orders (order_status, order_purchase_timestamp);
CREATE INDEX idx_products_category_id ON core.products (category_id);
CREATE INDEX idx_items_seller_id ON core.order_items (seller_id);
CREATE INDEX idx_items_product_id ON core.order_items (product_id);
CREATE INDEX idx_reviews_order_id ON core.reviews (order_id);

COMMENT ON TABLE core.order_items IS 'Гранулярность: одна исходная позиция (order_id, order_item_id).';
COMMENT ON TABLE core.reviews IS 'Гранулярность: одна связь review_id с order_id, а не обязательно один независимый отзыв.';
COMMENT ON COLUMN core.customers.customer_unique_id IS 'Сквозной идентификатор покупателя; подходит для анализа повторных заказов.';
COMMENT ON COLUMN core.orders.order_status IS 'Выручка кейса определяется статусом delivered, а не наличием даты доставки.';
