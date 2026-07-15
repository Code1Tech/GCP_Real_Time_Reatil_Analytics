CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_ai.customer_churn_training_data`
CLUSTER BY churn_label
AS

WITH parameters AS (
  SELECT
    DATE '2026-03-31' AS observation_date,
    180 AS feature_window_days,
    60 AS outcome_window_days
),

customer_features AS (
  SELECT
    s.customer_id,

    COUNT(DISTINCT s.transaction_id) AS order_count,
    SUM(s.total_amount) AS lifetime_value,
    AVG(s.total_amount) AS avg_order_value,
    SUM(s.quantity) AS total_units,
    COUNT(DISTINCT s.category) AS category_diversity,
    COUNT(DISTINCT s.product_id) AS product_diversity,
    COUNT(DISTINCT s.store_id) AS store_diversity,

    DATE_DIFF(
      p.observation_date,
      MAX(s.sales_date),
      DAY
    ) AS recency_days,

    DATE_DIFF(
      MAX(s.sales_date),
      MIN(s.sales_date),
      DAY
    ) AS customer_tenure_days,

    SAFE_DIVIDE(
      COUNT(DISTINCT s.transaction_id),
      NULLIF(
        DATE_DIFF(
          MAX(s.sales_date),
          MIN(s.sales_date),
          DAY
        ) + 1,
        0
      )
    ) * 30 AS monthly_purchase_frequency

  FROM `gcp-project-usecase.retail_silver.sales_unified_clean` s
  CROSS JOIN parameters p

  WHERE s.sales_date BETWEEN
    DATE_SUB(
      p.observation_date,
      INTERVAL p.feature_window_days DAY
    )
    AND p.observation_date

  GROUP BY
    s.customer_id,
    p.observation_date
),

return_features AS (
  SELECT
    r.customer_id,
    COUNT(DISTINCT r.return_id) AS return_count,
    SUM(r.completed_refund_amount) AS refund_amount
  FROM `gcp-project-usecase.retail_silver.returns_events_clean` r
  CROSS JOIN parameters p
  WHERE r.return_date BETWEEN
    DATE_SUB(
      p.observation_date,
      INTERVAL p.feature_window_days DAY
    )
    AND p.observation_date
  GROUP BY r.customer_id
),

future_activity AS (
  SELECT
    s.customer_id,
    COUNT(DISTINCT s.transaction_id) AS future_order_count
  FROM `gcp-project-usecase.retail_silver.sales_unified_clean` s
  CROSS JOIN parameters p
  WHERE s.sales_date BETWEEN
    DATE_ADD(p.observation_date, INTERVAL 1 DAY)
    AND DATE_ADD(
      p.observation_date,
      INTERVAL p.outcome_window_days DAY
    )
  GROUP BY s.customer_id
)

SELECT
  f.customer_id,
  f.order_count,
  f.lifetime_value,
  f.avg_order_value,
  f.total_units,
  f.category_diversity,
  f.product_diversity,
  f.store_diversity,
  f.recency_days,
  f.customer_tenure_days,
  f.monthly_purchase_frequency,

  COALESCE(r.return_count, 0) AS return_count,
  COALESCE(r.refund_amount, 0) AS refund_amount,

  COALESCE(a.future_order_count, 0) AS future_order_count,

  CASE
    WHEN COALESCE(a.future_order_count, 0) = 0 THEN 1
    ELSE 0
  END AS churn_label,

  DATE '2026-03-31' AS observation_date,
  CURRENT_TIMESTAMP() AS training_data_created_at

FROM customer_features f
LEFT JOIN return_features r
  USING (customer_id)
LEFT JOIN future_activity a
  USING (customer_id);