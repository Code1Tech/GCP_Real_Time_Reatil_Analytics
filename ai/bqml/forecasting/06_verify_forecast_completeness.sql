SELECT
  COUNT(*) AS forecast_rows,
  COUNT(DISTINCT product_id) AS forecasted_products,
  COUNT(DISTINCT forecast_date) AS forecast_days,
  MIN(forecast_date) AS first_forecast_date,
  MAX(forecast_date) AS last_forecast_date
FROM `gcp-project-usecase.retail_ai.demand_forecast_dashboard`;