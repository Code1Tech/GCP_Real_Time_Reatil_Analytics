SELECT
s.transaction_id,
s.customer_id
FROM `gcp-project-usecase.retail_bronze.sales_raw_enterprise` s
LEFT JOIN
`gcp-project-usecase.retail_bronze.customers_raw` c
ON s.customer_id=c.customer_id
WHERE c.customer_id IS NULL;