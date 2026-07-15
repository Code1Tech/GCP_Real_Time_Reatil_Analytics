CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_ai.demand_forecast_dashboard`
CLUSTER BY category, product_id
AS
WITH inventory AS (
  SELECT
    product_id,
    SUM(current_stock) AS current_stock,
    SUM(warehouse_stock) AS warehouse_stock,
    SUM(reorder_level) AS reorder_level
  FROM `gcp-project-usecase.retail_silver.latest_inventory_position`
  GROUP BY product_id
)

SELECT
  CURRENT_TIMESTAMP() AS dashboard_refresh_timestamp,
  DATE(f.forecast_timestamp) AS forecast_date,
  f.product_id,
  p.product_name,
  p.category,
  p.sub_category,
  p.brand,

  GREATEST(f.forecast_value, 0) AS forecasted_units,

  GREATEST(
    f.prediction_interval_lower_bound,
    0
  ) AS forecast_lower_bound,

  GREATEST(
    f.prediction_interval_upper_bound,
    0
  ) AS forecast_upper_bound,

  p.selling_price,

  GREATEST(f.forecast_value, 0) * p.selling_price
    AS forecasted_revenue,

  COALESCE(i.current_stock, 0) AS current_stock,
  COALESCE(i.warehouse_stock, 0) AS warehouse_stock,
  COALESCE(i.reorder_level, 0) AS reorder_level,

  SAFE_DIVIDE(
    COALESCE(i.current_stock, 0),
    NULLIF(GREATEST(f.forecast_value, 0), 0)
  ) AS estimated_stock_coverage_days,

  CASE
    WHEN COALESCE(i.current_stock, 0) = 0
      THEN 'Critical Stock Risk'
    WHEN COALESCE(i.current_stock, 0)
      < GREATEST(f.forecast_value, 0) * 3
      THEN 'High Stock Risk'
    WHEN COALESCE(i.current_stock, 0)
      < GREATEST(f.forecast_value, 0) * 7
      THEN 'Medium Stock Risk'
    ELSE 'Sufficient Stock'
  END AS forecast_inventory_status

FROM
  `gcp-project-usecase.retail_ai.product_demand_forecast_14_day` f

LEFT JOIN
  `gcp-project-usecase.retail_bronze.products_raw` p
ON f.product_id = p.product_id

LEFT JOIN inventory i
ON f.product_id = i.product_id
WHERE DATE(f.forecast_timestamp) >
  (
    SELECT MAX(sales_date)
    FROM `gcp-project-usecase.retail_ai.demand_training_data`
  );