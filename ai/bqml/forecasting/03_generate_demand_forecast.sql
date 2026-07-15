CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_ai.product_demand_forecast_14_day`
AS
SELECT
  CURRENT_TIMESTAMP() AS prediction_timestamp,
  *
FROM ML.FORECAST(
  MODEL `gcp-project-usecase.retail_ml.product_demand_forecast_model`,
  STRUCT(
    14 AS horizon,
    0.90 AS confidence_level
  )
);