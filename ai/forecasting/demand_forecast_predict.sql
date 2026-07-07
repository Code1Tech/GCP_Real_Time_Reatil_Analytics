CREATE OR REPLACE TABLE `gcp-project-usecase.retail_gold.ai_7_day_demand_forecast`
AS
SELECT
  *
FROM ML.FORECAST(
  MODEL `gcp-project-usecase.retail_ml.demand_forecast_model`,
  STRUCT(7 AS horizon, 0.8 AS confidence_level)
);