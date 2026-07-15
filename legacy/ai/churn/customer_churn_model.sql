CREATE OR REPLACE MODEL `gcp-project-usecase.retail_ml.customer_churn_model`
OPTIONS(
  MODEL_TYPE = 'LOGISTIC_REG',
  INPUT_LABEL_COLS = ['churn_label'],
  AUTO_CLASS_WEIGHTS = TRUE
) AS
SELECT
  order_count,
  lifetime_value,
  avg_order_value,
  recency_days,
  category_diversity,
  return_count,
  churn_label
FROM `gcp-project-usecase.retail_gold.ai_churn_features`;