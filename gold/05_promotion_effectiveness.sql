CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_gold.promotion_effectiveness`
CLUSTER BY campaign_id, region, category
AS

WITH eligible_sales AS (
  SELECT
    p.campaign_id,
    p.campaign_name,
    p.region,
    p.category,
    p.product_id AS campaign_product_id,
    p.discount_percent,
    p.start_date,
    p.end_date,
    p.campaign_status,

    s.transaction_id,
    s.customer_id,
    s.sales_date,
    s.product_id,
    s.quantity,
    s.total_amount,
    s.gross_profit,

    ROW_NUMBER() OVER (
      PARTITION BY s.transaction_id
      ORDER BY p.discount_percent DESC, p.event_timestamp DESC
    ) AS campaign_match_rank

  FROM `gcp-project-usecase.retail_silver.promotion_events_clean` p

  JOIN `gcp-project-usecase.retail_silver.sales_unified_clean` s
    ON s.sales_date BETWEEN p.start_date AND p.end_date
   AND s.region = p.region
   AND (
     s.product_id = p.product_id
     OR s.category = p.category
   )
)

SELECT
  campaign_id,
  campaign_name,
  region,
  category,
  campaign_product_id,
  discount_percent,
  start_date,
  end_date,
  campaign_status,

  COUNT(DISTINCT transaction_id) AS attributed_orders,
  COUNT(DISTINCT customer_id) AS attributed_customers,
  SUM(quantity) AS attributed_units,
  SUM(total_amount) AS attributed_revenue,
  SUM(gross_profit) AS attributed_profit,

  SAFE_DIVIDE(
    SUM(gross_profit),
    NULLIF(SUM(total_amount), 0)
  ) AS attributed_margin,

  'ESTIMATED_ATTRIBUTION' AS attribution_method,

  CURRENT_TIMESTAMP() AS gold_processed_timestamp

FROM eligible_sales
WHERE campaign_match_rank = 1

GROUP BY
  campaign_id,
  campaign_name,
  region,
  category,
  campaign_product_id,
  discount_percent,
  start_date,
  end_date,
  campaign_status;