CREATE OR REPLACE TABLE
`your-project-id.retail_silver.sales_clean`

PARTITION BY DATE(transaction_ts)

CLUSTER BY store_id, product_id

AS

SELECT

transaction_id,

transaction_ts,

DATE(transaction_ts) AS transaction_date,

store_id,

region,

product_id,

product_name,

category,

customer_id,

quantity,

unit_price,

discount_amount,

quantity * unit_price AS gross_sales,

(quantity * unit_price)
- discount_amount AS net_sales,

payment_method,

ingestion_ts

FROM `your-project-id.retail_bronze.sales_raw`

WHERE quantity > 0

QUALIFY ROW_NUMBER() OVER(

PARTITION BY transaction_id

ORDER BY ingestion_ts DESC

)=1;