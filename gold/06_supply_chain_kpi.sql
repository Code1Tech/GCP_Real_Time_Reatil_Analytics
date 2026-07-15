CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_gold.supply_chain_kpi`
PARTITION BY movement_date
CLUSTER BY warehouse_id, destination_region, shipment_status
AS

SELECT
  movement_date,
  warehouse_id,
  destination_region,
  destination_store_id,
  destination_store_name,
  category,
  brand,
  product_id,
  product_name,
  warehouse_event_type,
  shipment_status,

  COUNT(DISTINCT warehouse_event_id) AS shipment_count,
  SUM(quantity) AS total_quantity,
  AVG(expected_lead_time_days) AS average_expected_lead_time_days,
  COUNTIF(is_delayed) AS delayed_shipment_count,

  SAFE_DIVIDE(
    COUNTIF(is_delayed),
    COUNT(DISTINCT warehouse_event_id)
  ) AS delay_rate,

  COUNTIF(shipment_status = 'DELIVERED') AS delivered_shipment_count,

  SAFE_DIVIDE(
    COUNTIF(shipment_status = 'DELIVERED'),
    COUNT(DISTINCT warehouse_event_id)
  ) AS delivery_completion_rate,

  CURRENT_TIMESTAMP() AS gold_processed_timestamp

FROM `gcp-project-usecase.retail_silver.warehouse_movement_summary`

GROUP BY
  movement_date,
  warehouse_id,
  destination_region,
  destination_store_id,
  destination_store_name,
  category,
  brand,
  product_id,
  product_name,
  warehouse_event_type,
  shipment_status;