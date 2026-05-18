CREATE OR REPLACE TABLE `your-project-id.retail_bronze.inventory_raw`
(
inventory_event_id STRING,
event_ts TIMESTAMP,
store_id STRING,
warehouse_id STRING,
product_id STRING,
product_name STRING,
category STRING,
stock_on_hand INT64,
reorder_level INT64,
reorder_quantity INT64,
ingestion_ts TIMESTAMP
)
PARTITION BY DATE(event_ts)
CLUSTER BY store_id, product_id;