CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_ai.customer_churn_model_evaluation`
AS
SELECT
  CURRENT_TIMESTAMP() AS evaluation_timestamp,
  *
FROM ML.EVALUATE(
  MODEL `gcp-project-usecase.retail_ml.customer_churn_model`
);