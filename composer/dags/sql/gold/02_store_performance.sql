CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_gold.store_performance`
CLUSTER BY region, store_id
AS

WITH sales AS (
  SELECT
    store_id,
    store_name,
    region,
    COUNT(DISTINCT transaction_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(quantity) AS units_sold,
    SUM(total_amount) AS total_revenue,
    SUM(gross_profit) AS gross_profit,
    AVG(total_amount) AS average_order_value,
    SAFE_DIVIDE(
      SUM(gross_profit),
      NULLIF(SUM(net_sales_before_tax), 0)
    ) AS gross_margin
  FROM `gcp-project-usecase.retail_silver.sales_unified_clean`
  GROUP BY store_id, store_name, region
),

returns AS (
  SELECT
    store_id,
    COUNT(DISTINCT return_id) AS return_count,
    SUM(completed_refund_amount) AS refunded_amount
  FROM `gcp-project-usecase.retail_silver.returns_events_clean`
  GROUP BY store_id
),

inventory AS (
  SELECT
    store_id,
    COUNT(*) AS inventory_records,
    COUNTIF(inventory_status = 'STOCK_OUT') AS stockout_count,
    COUNTIF(inventory_status = 'UNDERSTOCK') AS understock_count,
    COUNTIF(inventory_status = 'OVERSTOCK') AS overstock_count,
    COUNTIF(inventory_status = 'HEALTHY') AS healthy_inventory_count
  FROM `gcp-project-usecase.retail_silver.latest_inventory_position`
  GROUP BY store_id
)

SELECT
  st.store_id,
  st.store_name,
  st.city,
  st.state,
  st.region,
  st.store_type,

  COALESCE(s.total_orders, 0) AS total_orders,
  COALESCE(s.unique_customers, 0) AS unique_customers,
  COALESCE(s.units_sold, 0) AS units_sold,
  COALESCE(s.total_revenue, 0) AS total_revenue,
  COALESCE(s.gross_profit, 0) AS gross_profit,
  COALESCE(s.gross_margin, 0) AS gross_margin,
  COALESCE(s.average_order_value, 0) AS average_order_value,

  COALESCE(r.return_count, 0) AS return_count,
  COALESCE(r.refunded_amount, 0) AS refunded_amount,

  SAFE_DIVIDE(
    COALESCE(r.return_count, 0),
    NULLIF(COALESCE(s.total_orders, 0), 0)
  ) AS return_rate,

  COALESCE(i.inventory_records, 0) AS inventory_records,
  COALESCE(i.stockout_count, 0) AS stockout_count,
  COALESCE(i.understock_count, 0) AS understock_count,
  COALESCE(i.overstock_count, 0) AS overstock_count,
  COALESCE(i.healthy_inventory_count, 0) AS healthy_inventory_count,

  ROUND(
    LEAST(
      100,
      (
        40 * SAFE_DIVIDE(
          COALESCE(s.total_revenue, 0),
          NULLIF(MAX(COALESCE(s.total_revenue, 0)) OVER (), 0)
        )
      ) +
      (
        30 * SAFE_DIVIDE(
          COALESCE(s.gross_profit, 0),
          NULLIF(MAX(COALESCE(s.gross_profit, 0)) OVER (), 0)
        )
      ) +
      (
        20 * (
          1 - LEAST(
            SAFE_DIVIDE(
              COALESCE(r.return_count, 0),
              NULLIF(COALESCE(s.total_orders, 0), 0)
            ),
            1
          )
        )
      ) +
      (
        10 * SAFE_DIVIDE(
          COALESCE(i.healthy_inventory_count, 0),
          NULLIF(COALESCE(i.inventory_records, 0), 0)
        )
      )
    ),
    2
  ) AS store_performance_score,

  CURRENT_TIMESTAMP() AS gold_processed_timestamp

FROM `gcp-project-usecase.retail_bronze.stores_raw` st

LEFT JOIN sales s
  ON st.store_id = s.store_id

LEFT JOIN returns r
  ON st.store_id = r.store_id

LEFT JOIN inventory i
  ON st.store_id = i.store_id;