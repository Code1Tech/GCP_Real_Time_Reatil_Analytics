CREATE OR REPLACE TABLE `gcp-project-usecase.retail_gold.executive_sales_kpi`
AS
SELECT
  sales_date,
  region,
  store_id,
  store_name,
  category,
  brand,
  COUNT(DISTINCT transaction_id) AS total_orders,
  COUNT(DISTINCT customer_id) AS unique_customers,
  SUM(quantity) AS total_quantity_sold,
  SUM(gross_sales) AS gross_sales,
  SUM(discount) AS total_discount,
  SUM(tax) AS total_tax,
  SUM(net_sales) AS net_sales,
  SUM(total_amount) AS total_revenue,
  SUM(gross_profit) AS gross_profit,
  SAFE_DIVIDE(SUM(gross_profit), SUM(net_sales)) AS gross_margin,
  AVG(total_amount) AS average_order_value,
  COUNTIF(is_returned = TRUE) AS return_count
FROM `gcp-project-usecase.retail_silver.enterprise_sales_clean`
GROUP BY sales_date, region, store_id, store_name, category, brand;

CREATE OR REPLACE TABLE `gcp-project-usecase.retail_gold.customer_kpi`
AS
SELECT
  customer_id,
  customer_name,
  loyalty_tier,
  gender,
  age,
  customer_city,
  customer_state,
  COUNT(DISTINCT transaction_id) AS total_orders,
  SUM(total_amount) AS customer_lifetime_value,
  AVG(total_amount) AS average_spend,
  MAX(sales_date) AS last_purchase_date,
  DATE_DIFF(CURRENT_DATE(), MAX(sales_date), DAY) AS days_since_last_purchase,
  CASE
    WHEN DATE_DIFF(CURRENT_DATE(), MAX(sales_date), DAY) > 120 THEN 'High Churn Risk'
    WHEN DATE_DIFF(CURRENT_DATE(), MAX(sales_date), DAY) > 60 THEN 'Medium Churn Risk'
    ELSE 'Low Churn Risk'
  END AS churn_risk_segment
FROM `gcp-project-usecase.retail_silver.enterprise_sales_clean`
GROUP BY customer_id, customer_name, loyalty_tier, gender, age, customer_city, customer_state;

CREATE OR REPLACE TABLE `gcp-project-usecase.retail_gold.inventory_health_kpi`
AS
SELECT
  i.store_id,
  st.store_name,
  st.region,
  i.product_id,
  p.product_name,
  p.category,
  p.brand,
  i.current_stock,
  i.warehouse_stock,
  i.reorder_level,
  CASE
    WHEN i.current_stock = 0 THEN 'Stock Out'
    WHEN i.current_stock < i.reorder_level THEN 'Understock'
    WHEN i.current_stock > i.reorder_level * 5 THEN 'Overstock'
    ELSE 'Healthy'
  END AS inventory_status,
  CASE
    WHEN i.current_stock < i.reorder_level THEN TRUE
    ELSE FALSE
  END AS reorder_required
FROM `gcp-project-usecase.retail_bronze.inventory_raw_enterprise` i
LEFT JOIN `gcp-project-usecase.retail_bronze.products_raw` p
ON i.product_id = p.product_id
LEFT JOIN `gcp-project-usecase.retail_bronze.stores_raw` st
ON i.store_id = st.store_id;

CREATE OR REPLACE TABLE `gcp-project-usecase.retail_gold.product_performance_kpi`
AS
SELECT
  product_id,
  product_name,
  category,
  sub_category,
  brand,
  SUM(quantity) AS total_units_sold,
  SUM(net_sales) AS total_net_sales,
  SUM(gross_profit) AS total_profit,
  SAFE_DIVIDE(SUM(gross_profit), SUM(net_sales)) AS margin_percent,
  COUNTIF(is_returned = TRUE) AS return_count,
  CASE
    WHEN SUM(quantity) >= 200 THEN 'Fast Moving'
    WHEN SUM(quantity) >= 50 THEN 'Medium Moving'
    ELSE 'Slow Moving'
  END AS product_velocity
FROM `gcp-project-usecase.retail_silver.enterprise_sales_clean`
GROUP BY product_id, product_name, category, sub_category, brand;