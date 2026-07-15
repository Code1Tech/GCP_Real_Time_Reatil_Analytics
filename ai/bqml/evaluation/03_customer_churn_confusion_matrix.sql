CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_ai.customer_churn_confusion_matrix`
AS

SELECT
  CURRENT_TIMESTAMP() AS evaluation_timestamp,
  *
FROM ML.CONFUSION_MATRIX(
  MODEL `gcp-project-usecase.retail_ml.customer_churn_model`,
  (
    SELECT
      order_count,
      lifetime_value,
      avg_order_value,
      total_units,
      category_diversity,
      product_diversity,
      store_diversity,
      recency_days,
      customer_tenure_days,
      monthly_purchase_frequency,
      return_count,
      refund_amount,
      churn_label
    FROM
      `gcp-project-usecase.retail_ai.customer_churn_training_data`
  ),
  STRUCT(0.5 AS threshold)
);