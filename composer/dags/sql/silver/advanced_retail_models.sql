-- ============================================================
-- 1. UNIFIED HISTORICAL + STREAMING SALES
-- ============================================================

CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_silver.sales_unified_clean`
PARTITION BY sales_date
CLUSTER BY store_id, product_id, customer_id
AS

WITH unified_sales AS (

  -- Historical batch sales
  SELECT
    transaction_id,
    transaction_timestamp,
    customer_id,
    product_id,
    store_id,
    quantity,
    unit_price,
    discount,
    tax,
    payment_method,
    salesperson,
    total_amount,
    'BATCH' AS source_system,
    transaction_id AS source_record_id

  FROM
    `gcp-project-usecase.retail_bronze.sales_raw_enterprise`

  UNION ALL

  -- Streaming sales events
  SELECT
    transaction_id,
    event_timestamp AS transaction_timestamp,
    customer_id,
    product_id,
    store_id,
    quantity,
    unit_price,
    discount,
    tax,
    payment_method,
    salesperson,
    total_amount,
    'STREAMING' AS source_system,
    event_id AS source_record_id

  FROM
    `gcp-project-usecase.retail_bronze.sales_events_raw`
),

deduplicated_sales AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY transaction_id
      ORDER BY transaction_timestamp DESC
    ) AS row_number
  FROM unified_sales
)

SELECT
  s.transaction_id,
  s.transaction_timestamp,
  DATE(s.transaction_timestamp) AS sales_date,

  s.customer_id,
  c.customer_name,
  c.gender,
  c.age,
  c.city AS customer_city,
  c.state AS customer_state,
  c.loyalty_tier,

  s.product_id,
  p.product_name,
  p.category,
  p.sub_category,
  p.brand,
  p.cost_price,
  p.selling_price,

  s.store_id,
  st.store_name,
  st.city AS store_city,
  st.state AS store_state,
  st.region,
  st.store_type,

  s.quantity,
  s.unit_price,
  s.discount,
  s.tax,
  s.total_amount,

  s.quantity * s.unit_price AS gross_sales,

  (s.quantity * s.unit_price) - s.discount
    AS net_sales_before_tax,

  (
    (s.quantity * s.unit_price)
    - s.discount
    + s.tax
  ) AS calculated_total_amount,

  (
    (s.quantity * s.unit_price)
    - s.discount
    - (s.quantity * p.cost_price)
  ) AS gross_profit,

  SAFE_DIVIDE(
    (
      (s.quantity * s.unit_price)
      - s.discount
      - (s.quantity * p.cost_price)
    ),
    NULLIF(
      (s.quantity * s.unit_price) - s.discount,
      0
    )
  ) AS gross_margin,

  s.payment_method,
  s.salesperson,
  s.source_system,
  s.source_record_id,

  CURRENT_TIMESTAMP() AS silver_processed_timestamp

FROM deduplicated_sales s

LEFT JOIN
  `gcp-project-usecase.retail_bronze.customers_raw` c
ON s.customer_id = c.customer_id

LEFT JOIN
  `gcp-project-usecase.retail_bronze.products_raw` p
ON s.product_id = p.product_id

LEFT JOIN
  `gcp-project-usecase.retail_bronze.stores_raw` st
ON s.store_id = st.store_id

WHERE s.row_number = 1
  AND s.quantity > 0
  AND s.unit_price > 0
  AND s.transaction_id IS NOT NULL;


-- ============================================================
-- 2. LATEST INVENTORY POSITION
-- ============================================================

CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_silver.latest_inventory_position`
CLUSTER BY store_id, product_id
AS

WITH latest_stream_event AS (
  SELECT
    event_id,
    event_timestamp,
    inventory_id,
    store_id,
    product_id,
    previous_stock,
    quantity_change,
    current_stock,
    warehouse_stock,
    reorder_level,
    change_reason,

    ROW_NUMBER() OVER (
      PARTITION BY store_id, product_id
      ORDER BY event_timestamp DESC
    ) AS row_number

  FROM
    `gcp-project-usecase.retail_bronze.inventory_events_raw`
),

stream_inventory AS (
  SELECT
    store_id,
    product_id,
    current_stock,
    warehouse_stock,
    reorder_level,
    event_timestamp AS last_updated,
    change_reason,
    'STREAMING' AS source_system

  FROM latest_stream_event
  WHERE row_number = 1
),

batch_inventory AS (
  SELECT
    store_id,
    product_id,
    current_stock,
    warehouse_stock,
    reorder_level,
    last_updated,
    'BATCH_LOAD' AS change_reason,
    'BATCH' AS source_system

  FROM
    `gcp-project-usecase.retail_bronze.inventory_raw_enterprise`
),

combined_inventory AS (
  SELECT * FROM stream_inventory

  UNION ALL

  SELECT b.*
  FROM batch_inventory b

  LEFT JOIN stream_inventory s
    ON b.store_id = s.store_id
   AND b.product_id = s.product_id

  WHERE s.store_id IS NULL
)

SELECT
  i.store_id,
  st.store_name,
  st.city AS store_city,
  st.state AS store_state,
  st.region,
  st.store_type,

  i.product_id,
  p.product_name,
  p.category,
  p.sub_category,
  p.brand,

  i.current_stock,
  i.warehouse_stock,
  i.reorder_level,
  i.last_updated,
  i.change_reason,
  i.source_system,

  CASE
    WHEN i.current_stock = 0 THEN 'STOCK_OUT'
    WHEN i.current_stock < i.reorder_level THEN 'UNDERSTOCK'
    WHEN i.current_stock > i.reorder_level * 5 THEN 'OVERSTOCK'
    ELSE 'HEALTHY'
  END AS inventory_status,

  CASE
    WHEN i.current_stock < i.reorder_level THEN TRUE
    ELSE FALSE
  END AS reorder_required,

  GREATEST(
    (i.reorder_level * 3) - i.current_stock,
    0
  ) AS recommended_reorder_quantity,

  CURRENT_TIMESTAMP() AS silver_processed_timestamp

FROM combined_inventory i

LEFT JOIN
  `gcp-project-usecase.retail_bronze.products_raw` p
ON i.product_id = p.product_id

LEFT JOIN
  `gcp-project-usecase.retail_bronze.stores_raw` st
ON i.store_id = st.store_id;


-- ============================================================
-- 3. RETURNS EVENTS CLEAN
-- ============================================================

CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_silver.returns_events_clean`
PARTITION BY return_date
CLUSTER BY store_id, product_id, customer_id
AS

SELECT
  r.event_id,
  r.return_id,
  r.event_timestamp,
  DATE(r.event_timestamp) AS return_date,

  r.transaction_id,
  r.customer_id,
  c.customer_name,
  c.loyalty_tier,

  r.product_id,
  p.product_name,
  p.category,
  p.sub_category,
  p.brand,

  r.store_id,
  st.store_name,
  st.region,

  r.return_quantity,
  r.refund_amount,
  r.return_reason,
  r.return_status,

  CASE
    WHEN r.return_status = 'REFUNDED'
      THEN r.refund_amount
    ELSE 0
  END AS completed_refund_amount,

  CURRENT_TIMESTAMP() AS silver_processed_timestamp

FROM
  `gcp-project-usecase.retail_bronze.return_events_raw` r

LEFT JOIN
  `gcp-project-usecase.retail_bronze.customers_raw` c
ON r.customer_id = c.customer_id

LEFT JOIN
  `gcp-project-usecase.retail_bronze.products_raw` p
ON r.product_id = p.product_id

LEFT JOIN
  `gcp-project-usecase.retail_bronze.stores_raw` st
ON r.store_id = st.store_id

WHERE r.return_quantity > 0
  AND r.refund_amount >= 0
  AND r.return_id IS NOT NULL;


-- ============================================================
-- 4. CUSTOMER BEHAVIOR SUMMARY
-- ============================================================

CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_silver.customer_behavior_summary`
CLUSTER BY customer_id
AS

SELECT
  e.customer_id,

  c.customer_name,
  c.gender,
  c.age,
  c.city,
  c.state,
  COALESCE(e.loyalty_tier, c.loyalty_tier)
    AS loyalty_tier,

  COUNT(*) AS total_customer_events,

  COUNTIF(
    e.customer_event_type = 'LOGIN'
  ) AS login_count,

  COUNTIF(
    e.customer_event_type = 'PRODUCT_VIEW'
  ) AS product_view_count,

  COUNTIF(
    e.customer_event_type = 'ADD_TO_CART'
  ) AS add_to_cart_count,

  COUNTIF(
    e.customer_event_type = 'REMOVE_FROM_CART'
  ) AS remove_from_cart_count,

  COUNTIF(
    e.customer_event_type = 'CHECKOUT_STARTED'
  ) AS checkout_started_count,

  COUNT(DISTINCT e.session_id)
    AS session_count,

  COUNT(DISTINCT e.product_id)
    AS unique_products_viewed,

  COUNT(DISTINCT e.channel)
    AS channel_count,

  MAX(e.event_timestamp)
    AS latest_customer_event_timestamp,

  ARRAY_AGG(
    e.channel
    ORDER BY e.event_timestamp DESC
    LIMIT 1
  )[SAFE_OFFSET(0)] AS latest_channel,

  ARRAY_AGG(
    e.device_type
    ORDER BY e.event_timestamp DESC
    LIMIT 1
  )[SAFE_OFFSET(0)] AS latest_device_type,

  SAFE_DIVIDE(
    COUNTIF(
      e.customer_event_type = 'ADD_TO_CART'
    ),
    NULLIF(
      COUNTIF(
        e.customer_event_type = 'PRODUCT_VIEW'
      ),
      0
    )
  ) AS view_to_cart_rate,

  SAFE_DIVIDE(
    COUNTIF(
      e.customer_event_type = 'CHECKOUT_STARTED'
    ),
    NULLIF(
      COUNTIF(
        e.customer_event_type = 'ADD_TO_CART'
      ),
      0
    )
  ) AS cart_to_checkout_rate,

  CURRENT_TIMESTAMP() AS silver_processed_timestamp

FROM
  `gcp-project-usecase.retail_bronze.customer_events_raw` e

LEFT JOIN
  `gcp-project-usecase.retail_bronze.customers_raw` c
ON e.customer_id = c.customer_id

GROUP BY
  e.customer_id,
  c.customer_name,
  c.gender,
  c.age,
  c.city,
  c.state,
  COALESCE(e.loyalty_tier, c.loyalty_tier);


-- ============================================================
-- 5. PROMOTION EVENTS CLEAN
-- ============================================================

CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_silver.promotion_events_clean`
PARTITION BY start_date
CLUSTER BY campaign_id, product_id, region
AS

SELECT
  event_id,
  event_timestamp,
  campaign_id,
  campaign_name,
  product_id,
  category,
  region,
  discount_percent,
  campaign_status,
  start_date,
  end_date,

  DATE_DIFF(
    end_date,
    start_date,
    DAY
  ) + 1 AS campaign_duration_days,

  CASE
    WHEN CURRENT_DATE() BETWEEN start_date AND end_date
         AND campaign_status = 'ACTIVE'
      THEN TRUE
    ELSE FALSE
  END AS is_currently_active,

  CURRENT_TIMESTAMP() AS silver_processed_timestamp

FROM
  `gcp-project-usecase.retail_bronze.promotion_events_raw`

WHERE campaign_id IS NOT NULL
  AND discount_percent BETWEEN 0 AND 100
  AND end_date >= start_date;


-- ============================================================
-- 6. WAREHOUSE MOVEMENT SUMMARY
-- ============================================================

CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_silver.warehouse_movement_summary`
PARTITION BY movement_date
CLUSTER BY warehouse_id, destination_store_id, product_id
AS

SELECT
  event_id,
  warehouse_event_id,
  event_timestamp,
  DATE(event_timestamp) AS movement_date,

  warehouse_id,
  destination_store_id,
  st.store_name AS destination_store_name,
  st.region AS destination_region,

  w.product_id,
  p.product_name,
  p.category,
  p.brand,

  quantity,
  warehouse_event_type,
  shipment_status,
  expected_delivery_date,

  DATE_DIFF(
    expected_delivery_date,
    DATE(event_timestamp),
    DAY
  ) AS expected_lead_time_days,

  CASE
    WHEN shipment_status = 'DELAYED'
      THEN TRUE
    ELSE FALSE
  END AS is_delayed,

  CURRENT_TIMESTAMP() AS silver_processed_timestamp

FROM
  `gcp-project-usecase.retail_bronze.warehouse_events_raw` w

LEFT JOIN
  `gcp-project-usecase.retail_bronze.products_raw` p
ON w.product_id = p.product_id

LEFT JOIN
  `gcp-project-usecase.retail_bronze.stores_raw` st
ON w.destination_store_id = st.store_id

WHERE quantity > 0
  AND warehouse_event_id IS NOT NULL;