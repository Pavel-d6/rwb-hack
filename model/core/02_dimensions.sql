--- 1. Все 99 441 исходные записи покупателей. DISTINCT по customer_unique_id
-- ЗАПРЕЩЁН: customer_id нужен для связи заказов с покупателями.
INSERT INTO core.customers (
    customer_id, customer_unique_id, customer_zip_code_prefix,
    customer_city, customer_state
)
SELECT
    NULLIF(BTRIM(customer_id), ''),
    NULLIF(BTRIM(customer_unique_id), ''),
    NULLIF(BTRIM(customer_zip_code_prefix), ''),
    NULLIF(BTRIM(customer_city), ''),
    NULLIF(BTRIM(customer_state), '')
FROM raw.customers;

-- 2. Продавцы.
INSERT INTO core.sellers (
    seller_id, seller_zip_code_prefix, seller_city, seller_state
)
SELECT
    NULLIF(BTRIM(seller_id), ''),
    NULLIF(BTRIM(seller_zip_code_prefix), ''),
    NULLIF(BTRIM(seller_city), ''),
    NULLIF(BTRIM(seller_state), '')
FROM raw.sellers;

-- 3. Отдельная техническая категория для пустых значений.
INSERT INTO core.categories (category_id, category_name_pt, category_name_en)
VALUES ('__unknown__', NULL, 'Unknown');

-- 4. Все исходные непустые категории товаров, даже без английского перевода.
WITH source_categories AS (
    SELECT DISTINCT NULLIF(BTRIM(product_category_name), '') AS category_id
    FROM raw.products
),
translations AS (
    SELECT
        NULLIF(BTRIM(product_category_name), '') AS category_id,
        MAX(NULLIF(BTRIM(product_category_name_english), '')) AS category_name_en
    FROM raw.product_category_translation
    GROUP BY 1
)
INSERT INTO core.categories (category_id, category_name_pt, category_name_en)
SELECT
    sc.category_id,
    sc.category_id,
    COALESCE(t.category_name_en, sc.category_id)
FROM source_categories sc
LEFT JOIN translations t USING (category_id)
WHERE sc.category_id IS NOT NULL;

-- 5. Товары. Неизвестную категорию НЕ отбрасываем.
INSERT INTO core.products (
    product_id, category_id, product_name_length,
    product_description_length, product_photos_qty, product_weight_g,
    product_length_cm, product_height_cm, product_width_cm
)
SELECT
    NULLIF(BTRIM(product_id), ''),
    COALESCE(NULLIF(BTRIM(product_category_name), ''), '__unknown__'),
    NULLIF(BTRIM(product_name_lenght), '')::INTEGER,
    NULLIF(BTRIM(product_description_lenght), '')::INTEGER,
    NULLIF(BTRIM(product_photos_qty), '')::INTEGER,
    NULLIF(BTRIM(product_weight_g), '')::NUMERIC(12,2),
    NULLIF(BTRIM(product_length_cm), '')::NUMERIC(12,2),
    NULLIF(BTRIM(product_height_cm), '')::NUMERIC(12,2),
    NULLIF(BTRIM(product_width_cm), '')::NUMERIC(12,2)
FROM raw.products;
