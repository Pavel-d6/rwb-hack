CREATE TABLE IF NOT EXISTS core.customers (
    customer_unique_id TEXT PRIMARY KEY,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT
);

TRUNCATE TABLE core.customers;

INSERT INTO core.customers
SELECT DISTINCT ON (customer_unique_id)
    customer_unique_id,
    NULLIF(TRIM(customer_zip_code_prefix), ''),
    NULLIF(TRIM(customer_city), ''),
    NULLIF(TRIM(customer_state), '')
FROM raw.customers
ORDER BY
    customer_unique_id,
    customer_id;






CREATE TABLE IF NOT EXISTS core.sellers (
    seller_id TEXT PRIMARY KEY,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT
);

TRUNCATE TABLE core.sellers;

INSERT INTO core.sellers
SELECT
    seller_id,
    NULLIF(TRIM(seller_zip_code_prefix), ''),
    NULLIF(TRIM(seller_city), ''),
    NULLIF(TRIM(seller_state), '')
FROM raw.sellers;





CREATE TABLE IF NOT EXISTS core.categories (
    category_id TEXT PRIMARY KEY,
    category_name_pt TEXT,
    category_name_en TEXT
);

TRUNCATE TABLE core.categories;

INSERT INTO core.categories
SELECT 
    COALESCE(NULLIF(TRIM(p.product_category_name), ''), '__unknown__') as category_id,
    COALESCE(NULLIF(TRIM(p.product_category_name), ''), '__unknown__') as category_name_pt,
    CASE 
        WHEN p.product_category_name IS NULL OR TRIM(p.product_category_name) = ''
        THEN 'Unknown'
        ELSE COALESCE(t.product_category_name_english, TRIM(p.product_category_name))
    END as category_name_en
FROM (
    SELECT DISTINCT product_category_name 
    FROM raw.products
) p
LEFT JOIN raw.product_category_translation t 
    ON p.product_category_name = t.product_category_name
ORDER BY category_id;






CREATE TABLE IF NOT EXISTS core.products (
    product_id TEXT PRIMARY KEY,
    category_id TEXT,
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g NUMERIC(12,2),
    product_length_cm NUMERIC(12,2),
    product_height_cm NUMERIC(12,2),
    product_width_cm NUMERIC(12,2)
);

TRUNCATE TABLE core.products;

INSERT INTO core.products
SELECT
    p.product_id,
    COALESCE(c.category_id, '__unknown__') as category_id,
    NULLIF(TRIM(p.product_name_lenght), '')::INTEGER as product_name_length,
    NULLIF(TRIM(p.product_description_lenght), '')::INTEGER as product_description_length,
    NULLIF(TRIM(p.product_photos_qty), '')::INTEGER as product_photos_qty,
    NULLIF(TRIM(p.product_weight_g), '')::NUMERIC(12,2) as product_weight_g,
    NULLIF(TRIM(p.product_length_cm), '')::NUMERIC(12,2) as product_length_cm,
    NULLIF(TRIM(p.product_height_cm), '')::NUMERIC(12,2) as product_height_cm,
    NULLIF(TRIM(p.product_width_cm), '')::NUMERIC(12,2) as product_width_cm
FROM raw.products p
LEFT JOIN core.categories c 
    ON p.product_category_name = c.category_name_pt;