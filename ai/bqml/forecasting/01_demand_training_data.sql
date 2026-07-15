CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_ai.demand_training_data`
PARTITION BY sales_date
CLUSTER BY product_id
AS

WITH date_bounds AS (
  SELECT
    MIN(sales_date) AS start_date,
    MAX(sales_date) AS end_date
  FROM `gcp-project-usecase.retail_silver.sales_unified_clean`
),

calendar AS (
  SELECT sales_date
  FROM date_bounds,
  UNNEST(
    GENERATE_DATE_ARRAY(start_date, end_date)
  ) AS sales_date
),

products AS (
  SELECT DISTINCT
    product_id,
    product_name,
    category,
    brand
  FROM `gcp-project-usecase.retail_silver.sales_unified_clean`
  WHERE product_id IS NOT NULL
),

daily_sales AS (
  SELECT
    sales_date,
    product_id,
    SUM(quantity) AS daily_units_sold,
    SUM(total_amount) AS daily_revenue
  FROM `gcp-project-usecase.retail_silver.sales_unified_clean`
  WHERE sales_date IS NOT NULL
    AND product_id IS NOT NULL
    AND quantity > 0
  GROUP BY sales_date, product_id
)

SELECT
  c.sales_date,
  p.product_id,
  p.product_name,
  p.category,
  p.brand,
  COALESCE(s.daily_units_sold, 0) AS daily_units_sold,
  COALESCE(s.daily_revenue, 0) AS daily_revenue
FROM calendar c
CROSS JOIN products p
LEFT JOIN daily_sales s
  ON c.sales_date = s.sales_date
 AND p.product_id = s.product_id;