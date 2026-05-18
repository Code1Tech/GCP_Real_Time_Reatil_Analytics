CREATE OR REPLACE TABLE `your-project-id.retail_bronze.customer_raw`
(
customer_id STRING,
customer_name STRING,
email STRING,
loyalty_tier STRING,
city STRING,
state STRING,
signup_date DATE,
ingestion_ts TIMESTAMP
);