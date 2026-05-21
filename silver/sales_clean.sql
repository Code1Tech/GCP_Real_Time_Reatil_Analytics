CREATE OR REPLACE TABLE
`gcp-project-usecase.retail_silver.sales_clean`
PARTITION BY DATE(transaction_ts)
CLUSTER BY store_id, product_id
AS

SELECT

    transaction_id,

    TIMESTAMP(transaction_ts) AS transaction_ts,

    store_id,

    region,

    product_id,

    product_name,

    category,

    customer_id,

    quantity,

    unit_price,

    discount_amount,

    (quantity * unit_price) - discount_amount
        AS net_sales_amount,

    payment_method,

    TIMESTAMP(ingestion_ts) AS ingestion_ts

FROM
`gcp-project-usecase.retail_bronze.sales_raw`

WHERE quantity > 0