SELECT
  forecast_date,
  category,
  ROUND(SUM(forecasted_units), 2) AS forecasted_units,
  ROUND(SUM(forecasted_revenue), 2) AS forecasted_revenue,
  COUNTIF(
    forecast_inventory_status IN (
      'Critical Stock Risk',
      'High Stock Risk'
    )
  ) AS high_risk_products
FROM `gcp-project-usecase.retail_ai.demand_forecast_dashboard`
GROUP BY
  forecast_date,
  category
ORDER BY
  forecast_date,
  forecasted_revenue DESC;