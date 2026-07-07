CREATE OR REPLACE TABLE `gcp-project-usecase.retail_bronze.customers_raw`
(
  customer_id STRING,
  customer_name STRING,
  gender STRING,
  age INT64,
  city STRING,
  state STRING,
  loyalty_tier STRING,
  joining_date DATE,
  email STRING,
  phone STRING
);

CREATE OR REPLACE TABLE `gcp-project-usecase.retail_bronze.products_raw`
(
  product_id STRING,
  product_name STRING,
  category STRING,
  sub_category STRING,
  brand STRING,
  cost_price NUMERIC,
  selling_price NUMERIC,
  supplier STRING,
  reorder_level INT64
);

CREATE OR REPLACE TABLE `gcp-project-usecase.retail_bronze.stores_raw`
(
  store_id STRING,
  store_name STRING,
  city STRING,
  state STRING,
  region STRING,
  store_type STRING,
  opening_date DATE
);

CREATE OR REPLACE TABLE `gcp-project-usecase.retail_bronze.inventory_raw_enterprise`
(
  inventory_id STRING,
  store_id STRING,
  product_id STRING,
  current_stock INT64,
  warehouse_stock INT64,
  reorder_level INT64,
  last_updated TIMESTAMP
);

CREATE OR REPLACE TABLE `gcp-project-usecase.retail_bronze.promotions_raw`
(
  campaign_id STRING,
  campaign_name STRING,
  start_date DATE,
  end_date DATE,
  discount_percent INT64
);

CREATE OR REPLACE TABLE `gcp-project-usecase.retail_bronze.sales_raw_enterprise`
(
  transaction_id STRING,
  transaction_timestamp TIMESTAMP,
  customer_id STRING,
  product_id STRING,
  store_id STRING,
  quantity INT64,
  unit_price NUMERIC,
  discount NUMERIC,
  tax NUMERIC,
  payment_method STRING,
  salesperson STRING,
  total_amount NUMERIC
);

CREATE OR REPLACE TABLE `gcp-project-usecase.retail_bronze.returns_raw`
(
  return_id STRING,
  transaction_id STRING,
  return_reason STRING,
  return_date DATE
);