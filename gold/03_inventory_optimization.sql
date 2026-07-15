CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_gold.inventory_optimization`
CLUSTER BY risk_level, store_id, product_id
AS

WITH recent_sales AS (
  SELECT
    store_id,
    product_id,
    SUM(quantity) AS units_sold_30_days,
    COUNT(DISTINCT sales_date) AS active_sales_days,
    SAFE_DIVIDE(
      SUM(quantity),
      NULLIF(COUNT(DISTINCT sales_date), 0)
    ) AS average_daily_units
  FROM `gcp-project-usecase.retail_silver.sales_unified_clean`
  WHERE sales_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  GROUP BY store_id, product_id
)

SELECT
  i.store_id,
  i.store_name,
  i.region,
  i.product_id,
  i.product_name,
  i.category,
  i.sub_category,
  i.brand,

  i.current_stock,
  i.warehouse_stock,
  i.reorder_level,
  i.inventory_status,
  i.reorder_required,
  i.last_updated,

  COALESCE(s.units_sold_30_days, 0) AS units_sold_30_days,
  COALESCE(s.active_sales_days, 0) AS active_sales_days,
  COALESCE(s.average_daily_units, 0) AS average_daily_units,

  SAFE_DIVIDE(
    i.current_stock,
    NULLIF(s.average_daily_units, 0)
  ) AS estimated_days_of_stock,

  CASE
    WHEN i.current_stock = 0 THEN 1.00
    WHEN COALESCE(s.average_daily_units, 0) = 0 THEN 0.10
    WHEN SAFE_DIVIDE(i.current_stock, s.average_daily_units) <= 3
      THEN 0.95
    WHEN SAFE_DIVIDE(i.current_stock, s.average_daily_units) <= 7
      THEN 0.75
    WHEN SAFE_DIVIDE(i.current_stock, s.average_daily_units) <= 14
      THEN 0.40
    ELSE 0.10
  END AS stockout_risk_score,

  CASE
    WHEN i.current_stock = 0 THEN 'Critical'
    WHEN COALESCE(s.average_daily_units, 0) > 0
      AND SAFE_DIVIDE(i.current_stock, s.average_daily_units) <= 3
      THEN 'Critical'
    WHEN COALESCE(s.average_daily_units, 0) > 0
      AND SAFE_DIVIDE(i.current_stock, s.average_daily_units) <= 7
      THEN 'High'
    WHEN i.current_stock < i.reorder_level
      THEN 'Medium'
    ELSE 'Low'
  END AS risk_level,

  GREATEST(
    CAST(
      CEIL(
        GREATEST(
          i.reorder_level * 3,
          COALESCE(s.average_daily_units, 0) * 30
        ) - i.current_stock
      ) AS INT64
    ),
    0
  ) AS optimized_reorder_quantity,

  CASE
    WHEN i.current_stock < i.reorder_level
      AND i.warehouse_stock >
        GREATEST(i.reorder_level * 3, i.current_stock)
      THEN 'Transfer from warehouse'
    WHEN i.current_stock < i.reorder_level
      THEN 'Create purchase order'
    WHEN i.inventory_status = 'OVERSTOCK'
      THEN 'Reduce replenishment or transfer stock'
    ELSE 'No action'
  END AS recommended_action,

  CURRENT_TIMESTAMP() AS gold_processed_timestamp

FROM `gcp-project-usecase.retail_silver.latest_inventory_position` i

LEFT JOIN recent_sales s
  ON i.store_id = s.store_id
 AND i.product_id = s.product_id;