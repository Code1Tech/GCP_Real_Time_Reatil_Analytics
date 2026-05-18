CREATE OR REPLACE TABLE
`your-project-id.retail_gold.daily_sales_kpi`

AS

SELECT

transaction_date,

region,

store_id,

SUM(net_sales) AS revenue,

SUM(quantity) AS units_sold,

COUNT(DISTINCT transaction_id)
AS total_transactions,

AVG(net_sales)
AS avg_transaction_value

FROM
`your-project-id.retail_silver.sales_clean`

GROUP BY
1,2,3;