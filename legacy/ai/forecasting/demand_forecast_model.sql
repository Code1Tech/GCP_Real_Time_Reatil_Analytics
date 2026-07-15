CREATE OR REPLACE MODEL `gcp-project-usecase.retail_ml.demand_forecast_model`
OPTIONS(
  MODEL_TYPE = 'ARIMA_PLUS',
  TIME_SERIES_TIMESTAMP_COL = 'sales_date',
  TIME_SERIES_DATA_COL = 'daily_units_sold',
  TIME_SERIES_ID_COL = 'product_id',
  AUTO_ARIMA = TRUE
) AS
SELECT
  sales_date,
  product_id,
  daily_units_sold
FROM `gcp-project-usecase.retail_gold.ai_demand_forecasting_features`;