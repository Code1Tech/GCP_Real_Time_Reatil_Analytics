CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_ai.customer_churn_global_explain`
AS

SELECT
  CURRENT_TIMESTAMP() AS evaluation_timestamp,
  *
FROM ML.GLOBAL_EXPLAIN(
  MODEL `gcp-project-usecase.retail_ml.customer_churn_model`
);