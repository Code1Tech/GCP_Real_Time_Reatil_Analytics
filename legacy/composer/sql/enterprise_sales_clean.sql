CREATE OR REPLACE TABLE `gcp-project-usecase.retail_silver.enterprise_sales_clean`
PARTITION BY DATE(transaction_timestamp)
CLUSTER BY store_id, product_id, customer_id
AS
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
  (s.quantity * s.unit_price) - s.discount AS net_sales,
  ((s.quantity * s.unit_price) - s.discount) - (s.quantity * p.cost_price) AS gross_profit,

  s.payment_method,
  s.salesperson,

  CASE WHEN r.transaction_id IS NOT NULL THEN TRUE ELSE FALSE END AS is_returned,
  r.return_reason

FROM `gcp-project-usecase.retail_bronze.sales_raw_enterprise` s
LEFT JOIN `gcp-project-usecase.retail_bronze.customers_raw` c
  ON s.customer_id = c.customer_id
LEFT JOIN `gcp-project-usecase.retail_bronze.products_raw` p
  ON s.product_id = p.product_id
LEFT JOIN `gcp-project-usecase.retail_bronze.stores_raw` st
  ON s.store_id = st.store_id
LEFT JOIN `gcp-project-usecase.retail_bronze.returns_raw` r
  ON s.transaction_id = r.transaction_id
WHERE s.quantity > 0
  AND s.unit_price > 0;