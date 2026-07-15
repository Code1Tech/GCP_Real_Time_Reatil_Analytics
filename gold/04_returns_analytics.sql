CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_gold.returns_analytics`
PARTITION BY return_date
CLUSTER BY region, category, return_reason
AS

SELECT
  return_date,
  region,
  store_id,
  store_name,
  category,
  sub_category,
  brand,
  product_id,
  product_name,
  return_reason,
  return_status,

  COUNT(DISTINCT return_id) AS return_count,
  COUNT(DISTINCT customer_id) AS impacted_customers,
  SUM(return_quantity) AS returned_quantity,
  SUM(refund_amount) AS requested_refund_amount,
  SUM(completed_refund_amount) AS completed_refund_amount,
  AVG(refund_amount) AS average_refund_amount,

  CURRENT_TIMESTAMP() AS gold_processed_timestamp

FROM `gcp-project-usecase.retail_silver.returns_events_clean`

GROUP BY
  return_date,
  region,
  store_id,
  store_name,
  category,
  sub_category,
  brand,
  product_id,
  product_name,
  return_reason,
  return_status;