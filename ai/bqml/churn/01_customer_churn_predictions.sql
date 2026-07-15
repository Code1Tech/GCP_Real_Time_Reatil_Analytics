CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_ai.customer_churn_predictions`
AS

WITH predictions AS (
  SELECT *
  FROM ML.PREDICT(
    MODEL `gcp-project-usecase.retail_ml.customer_churn_model`,
    (
      SELECT
        customer_id,

        total_orders AS order_count,
        customer_lifetime_value AS lifetime_value,
        average_order_value AS avg_order_value,
        recency_days,
        unique_categories_purchased AS category_diversity,
        total_returns AS return_count

      FROM `gcp-project-usecase.retail_gold.customer_360`

      WHERE customer_id IS NOT NULL
        AND recency_days IS NOT NULL
    )
  )
),

scored AS (
  SELECT
    CURRENT_TIMESTAMP() AS prediction_timestamp,

    customer_id,
    order_count,
    lifetime_value,
    avg_order_value,
    recency_days,
    category_diversity,
    return_count,

    predicted_churn_label,

    COALESCE(
      (
        SELECT probability_row.prob
        FROM UNNEST(predicted_churn_label_probs) AS probability_row
        WHERE probability_row.label = 1
        LIMIT 1
      ),
      0.0
    ) AS churn_probability

  FROM predictions
)

SELECT
  prediction_timestamp,

  customer_id,
  order_count,
  lifetime_value,
  avg_order_value,
  recency_days,
  category_diversity,
  return_count,

  predicted_churn_label,
  churn_probability,

  CASE
    WHEN churn_probability >= 0.80 THEN 'Critical'
    WHEN churn_probability >= 0.60 THEN 'High'
    WHEN churn_probability >= 0.40 THEN 'Medium'
    ELSE 'Low'
  END AS churn_risk,

  CASE
    WHEN churn_probability >= 0.80
         AND lifetime_value >= 100000
      THEN 'Immediate retention call and premium personalized offer'

    WHEN churn_probability >= 0.80
      THEN 'Immediate retention call and high-value incentive'

    WHEN churn_probability >= 0.60
         AND lifetime_value >= 25000
      THEN 'Send targeted loyalty incentive'

    WHEN churn_probability >= 0.60
      THEN 'Launch high-priority retention campaign'

    WHEN churn_probability >= 0.40
      THEN 'Enroll customer in retention campaign'

    ELSE 'Continue standard engagement'
  END AS recommended_retention_action,

  CASE
    WHEN churn_probability >= 0.80
         AND lifetime_value >= 100000
      THEN 1

    WHEN churn_probability >= 0.60
         AND lifetime_value >= 25000
      THEN 2

    WHEN churn_probability >= 0.40
      THEN 3

    ELSE 4
  END AS retention_priority,

  CASE
    WHEN lifetime_value >= 100000 THEN 'High Value'
    WHEN lifetime_value >= 25000 THEN 'Medium Value'
    WHEN lifetime_value > 0 THEN 'Standard Value'
    ELSE 'No Value'
  END AS customer_value_segment,

  CURRENT_TIMESTAMP() AS output_refresh_timestamp

FROM scored;