CREATE OR REPLACE TABLE `your-project-id.retail_bronze.sales_raw`
(
transaction_id STRING,
transaction_ts TIMESTAMP,
store_id STRING,
region STRING,
product_id STRING,
product_name STRING,
category STRING,
customer_id STRING,
quantity INT64,
unit_price NUMERIC,
discount_amount NUMERIC,
payment_method STRING,
ingestion_ts TIMESTAMP
)
PARTITION BY DATE(transaction_ts)
CLUSTER BY store_id, product_id;