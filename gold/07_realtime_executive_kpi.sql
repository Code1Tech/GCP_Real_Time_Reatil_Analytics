CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_gold.realtime_executive_kpi`
PARTITION BY sales_date
CLUSTER BY region, source_system
AS

SELECT
  sales_date,
  region,
  source_system,

  COUNT(DISTINCT transaction_id) AS total_orders,
  COUNT(DISTINCT customer_id) AS unique_customers,
  COUNT(DISTINCT store_id) AS active_stores,
  COUNT(DISTINCT product_id) AS products_sold,

  SUM(quantity) AS units_sold,
  SUM(gross_sales) AS gross_sales,
  SUM(discount) AS total_discount,
  SUM(tax) AS total_tax,
  SUM(total_amount) AS total_revenue,
  SUM(gross_profit) AS gross_profit,

  SAFE_DIVIDE(
    SUM(gross_profit),
    NULLIF(SUM(net_sales_before_tax), 0)
  ) AS gross_margin,

  SAFE_DIVIDE(
    SUM(total_amount),
    COUNT(DISTINCT transaction_id)
  ) AS average_order_value,

  CURRENT_TIMESTAMP() AS gold_processed_timestamp

FROM `gcp-project-usecase.retail_silver.sales_unified_clean`

GROUP BY
  sales_date,
  region,
  source_system;