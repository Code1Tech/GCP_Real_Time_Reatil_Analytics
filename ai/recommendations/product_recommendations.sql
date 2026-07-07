CREATE OR REPLACE TABLE `gcp-project-usecase.retail_gold.ai_product_recommendations`
AS
WITH customer_products AS (
  SELECT DISTINCT
    customer_id,
    product_id,
    product_name,
    category
  FROM `gcp-project-usecase.retail_silver.enterprise_sales_clean`
),

product_pairs AS (
  SELECT
    a.product_id AS product_id,
    a.product_name AS product_name,
    a.category AS category,
    b.product_id AS recommended_product_id,
    b.product_name AS recommended_product_name,
    b.category AS recommended_category,
    COUNT(DISTINCT a.customer_id) AS common_customer_count
  FROM customer_products a
  JOIN customer_products b
    ON a.customer_id = b.customer_id
   AND a.product_id != b.product_id
  GROUP BY
    product_id,
    product_name,
    category,
    recommended_product_id,
    recommended_product_name,
    recommended_category
)

SELECT
  *,
  RANK() OVER (
    PARTITION BY product_id
    ORDER BY common_customer_count DESC
  ) AS recommendation_rank
FROM product_pairs
QUALIFY recommendation_rank <= 5;