CREATE OR REPLACE MODEL
`gcp-project-usecase.retail_ml.customer_churn_model`
OPTIONS(
  MODEL_TYPE = 'LOGISTIC_REG',
  INPUT_LABEL_COLS = ['churn_label'],
  AUTO_CLASS_WEIGHTS = TRUE,
  DATA_SPLIT_METHOD = 'RANDOM',
  DATA_SPLIT_EVAL_FRACTION = 0.20,
  ENABLE_GLOBAL_EXPLAIN = TRUE,
  MAX_ITERATIONS = 50,
  EARLY_STOP = TRUE
) AS
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
FROM `gcp-project-usecase.retail_ai.customer_churn_training_data`;