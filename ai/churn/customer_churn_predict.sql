CREATE OR REPLACE TABLE `gcp-project-usecase.retail_gold.ai_customer_churn_predictions`
AS
SELECT
  *
FROM ML.PREDICT(
  MODEL `gcp-project-usecase.retail_ml.customer_churn_model`,
  (
    SELECT
      customer_id,
      order_count,
      lifetime_value,
      avg_order_value,
      recency_days,
      category_diversity,
      return_count
    FROM `gcp-project-usecase.retail_gold.ai_churn_features`
  )
);