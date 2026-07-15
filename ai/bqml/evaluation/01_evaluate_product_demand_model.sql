CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_ai.product_demand_model_evaluation`
AS
SELECT
  CURRENT_TIMESTAMP() AS evaluation_timestamp,
  *
FROM ML.ARIMA_EVALUATE(
  MODEL `gcp-project-usecase.retail_ml.product_demand_forecast_model`,
  STRUCT(FALSE AS show_all_candidate_models)
);