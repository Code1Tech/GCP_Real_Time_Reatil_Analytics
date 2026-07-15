CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_gold.customer_360`
CLUSTER BY customer_id, churn_risk_segment
AS

WITH sales AS (
  SELECT
    customer_id,
    COUNT(DISTINCT transaction_id) AS total_orders,
    SUM(quantity) AS total_units_purchased,
    SUM(total_amount) AS lifetime_revenue,
    SUM(gross_profit) AS lifetime_profit,
    AVG(total_amount) AS average_order_value,
    COUNT(DISTINCT product_id) AS unique_products_purchased,
    COUNT(DISTINCT category) AS unique_categories_purchased,
    MIN(sales_date) AS first_purchase_date,
    MAX(sales_date) AS last_purchase_date,
    COUNTIF(source_system = 'STREAMING') AS streaming_order_count,

    ARRAY_AGG(
      category
      IGNORE NULLS
      ORDER BY sales_date DESC
      LIMIT 1
    )[SAFE_OFFSET(0)] AS latest_category

  FROM `gcp-project-usecase.retail_silver.sales_unified_clean`
  GROUP BY customer_id
),

returns AS (
  SELECT
    customer_id,
    COUNT(DISTINCT return_id) AS total_returns,
    SUM(return_quantity) AS total_return_quantity,
    SUM(completed_refund_amount) AS total_refund_amount
  FROM `gcp-project-usecase.retail_silver.returns_events_clean`
  GROUP BY customer_id
),

behavior AS (
  SELECT
    customer_id,
    total_customer_events,
    product_view_count,
    add_to_cart_count,
    checkout_started_count,
    session_count,
    unique_products_viewed,
    latest_channel,
    latest_device_type,
    view_to_cart_rate,
    cart_to_checkout_rate
  FROM `gcp-project-usecase.retail_silver.customer_behavior_summary`
)

SELECT
  c.customer_id,
  c.customer_name,
  c.gender,
  c.age,
  c.city,
  c.state,
  c.loyalty_tier,
  c.joining_date,

  COALESCE(s.total_orders, 0) AS total_orders,
  COALESCE(s.total_units_purchased, 0) AS total_units_purchased,
  COALESCE(s.lifetime_revenue, 0) AS customer_lifetime_value,
  COALESCE(s.lifetime_profit, 0) AS customer_lifetime_profit,
  COALESCE(s.average_order_value, 0) AS average_order_value,
  COALESCE(s.unique_products_purchased, 0) AS unique_products_purchased,
  COALESCE(s.unique_categories_purchased, 0) AS unique_categories_purchased,
  s.first_purchase_date,
  s.last_purchase_date,

  CASE
    WHEN s.last_purchase_date IS NULL THEN NULL
    ELSE DATE_DIFF(CURRENT_DATE(), s.last_purchase_date, DAY)
  END AS recency_days,

  COALESCE(r.total_returns, 0) AS total_returns,
  COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
  COALESCE(r.total_refund_amount, 0) AS total_refund_amount,

  SAFE_DIVIDE(
    COALESCE(r.total_returns, 0),
    NULLIF(COALESCE(s.total_orders, 0), 0)
  ) AS return_rate,

  COALESCE(b.total_customer_events, 0) AS total_customer_events,
  COALESCE(b.product_view_count, 0) AS product_view_count,
  COALESCE(b.add_to_cart_count, 0) AS add_to_cart_count,
  COALESCE(b.checkout_started_count, 0) AS checkout_started_count,
  COALESCE(b.session_count, 0) AS session_count,
  COALESCE(b.unique_products_viewed, 0) AS unique_products_viewed,
  b.latest_channel,
  b.latest_device_type,
  b.view_to_cart_rate,
  b.cart_to_checkout_rate,
  s.latest_category,

  CASE
    WHEN s.last_purchase_date IS NULL THEN 'No Purchase'
    WHEN DATE_DIFF(CURRENT_DATE(), s.last_purchase_date, DAY) > 120
      THEN 'High'
    WHEN DATE_DIFF(CURRENT_DATE(), s.last_purchase_date, DAY) > 60
      THEN 'Medium'
    ELSE 'Low'
  END AS churn_risk_segment,

  CASE
    WHEN COALESCE(s.lifetime_revenue, 0) >= 100000 THEN 'High Value'
    WHEN COALESCE(s.lifetime_revenue, 0) >= 25000 THEN 'Medium Value'
    WHEN COALESCE(s.lifetime_revenue, 0) > 0 THEN 'Standard'
    ELSE 'No Purchase'
  END AS customer_value_segment,

  CURRENT_TIMESTAMP() AS gold_processed_timestamp

FROM `gcp-project-usecase.retail_bronze.customers_raw` c

LEFT JOIN sales s
  ON c.customer_id = s.customer_id

LEFT JOIN returns r
  ON c.customer_id = r.customer_id

LEFT JOIN behavior b
  ON c.customer_id = b.customer_id;