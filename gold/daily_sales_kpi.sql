CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_gold.daily_sales_kpi`
AS

SELECT

    DATE(transaction_ts) AS sales_date,

    region,

    store_id,

    category,

    SUM(net_sales_amount)
        AS total_sales,

    SUM(quantity)
        AS total_units_sold,

    COUNT(DISTINCT transaction_id)
        AS total_transactions,

    AVG(net_sales_amount)
        AS avg_transaction_value

FROM
`gcp-project-usecase.retail_silver.sales_clean`

GROUP BY
1,2,3,4