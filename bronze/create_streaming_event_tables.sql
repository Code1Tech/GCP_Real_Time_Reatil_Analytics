CREATE TABLE IF NOT EXISTS
`gcp-project-usecase.retail_bronze.sales_events_raw`
(
  event_id STRING,
  event_type STRING,
  event_timestamp TIMESTAMP,
  transaction_id STRING,
  customer_id STRING,
  product_id STRING,
  store_id STRING,
  quantity INT64,
  unit_price NUMERIC,
  discount NUMERIC,
  tax NUMERIC,
  payment_method STRING,
  salesperson STRING,
  total_amount NUMERIC,
  ingestion_timestamp TIMESTAMP
)
PARTITION BY DATE(event_timestamp)
CLUSTER BY store_id, product_id, customer_id;

CREATE TABLE IF NOT EXISTS
`gcp-project-usecase.retail_bronze.inventory_events_raw`
(
  event_id STRING,
  event_type STRING,
  event_timestamp TIMESTAMP,
  inventory_id STRING,
  store_id STRING,
  product_id STRING,
  previous_stock INT64,
  quantity_change INT64,
  current_stock INT64,
  warehouse_stock INT64,
  reorder_level INT64,
  change_reason STRING,
  ingestion_timestamp TIMESTAMP
)
PARTITION BY DATE(event_timestamp)
CLUSTER BY store_id, product_id;

CREATE TABLE IF NOT EXISTS
`gcp-project-usecase.retail_bronze.return_events_raw`
(
  event_id STRING,
  event_type STRING,
  event_timestamp TIMESTAMP,
  return_id STRING,
  transaction_id STRING,
  customer_id STRING,
  product_id STRING,
  store_id STRING,
  return_quantity INT64,
  refund_amount NUMERIC,
  return_reason STRING,
  return_status STRING,
  ingestion_timestamp TIMESTAMP
)
PARTITION BY DATE(event_timestamp)
CLUSTER BY store_id, product_id, customer_id;

CREATE TABLE IF NOT EXISTS
`gcp-project-usecase.retail_bronze.promotion_events_raw`
(
  event_id STRING,
  event_type STRING,
  event_timestamp TIMESTAMP,
  campaign_id STRING,
  campaign_name STRING,
  product_id STRING,
  category STRING,
  region STRING,
  discount_percent NUMERIC,
  campaign_status STRING,
  start_date DATE,
  end_date DATE,
  ingestion_timestamp TIMESTAMP
)
PARTITION BY DATE(event_timestamp)
CLUSTER BY campaign_id, category, region;

CREATE TABLE IF NOT EXISTS
`gcp-project-usecase.retail_bronze.customer_events_raw`
(
  event_id STRING,
  event_type STRING,
  event_timestamp TIMESTAMP,
  customer_id STRING,
  customer_event_type STRING,
  channel STRING,
  device_type STRING,
  store_id STRING,
  product_id STRING,
  session_id STRING,
  loyalty_tier STRING,
  ingestion_timestamp TIMESTAMP
)
PARTITION BY DATE(event_timestamp)
CLUSTER BY customer_id, customer_event_type, channel;

CREATE TABLE IF NOT EXISTS
`gcp-project-usecase.retail_bronze.warehouse_events_raw`
(
  event_id STRING,
  event_type STRING,
  event_timestamp TIMESTAMP,
  warehouse_event_id STRING,
  warehouse_id STRING,
  destination_store_id STRING,
  product_id STRING,
  quantity INT64,
  warehouse_event_type STRING,
  shipment_status STRING,
  expected_delivery_date DATE,
  ingestion_timestamp TIMESTAMP
)
PARTITION BY DATE(event_timestamp)
CLUSTER BY warehouse_id, destination_store_id, product_id;

CREATE TABLE IF NOT EXISTS
`gcp-project-usecase.retail_bronze.failed_retail_events`
(
  failed_timestamp TIMESTAMP,
  event_type STRING,
  raw_payload STRING,
  error_message STRING,
  dataflow_job_name STRING
)
PARTITION BY DATE(failed_timestamp);