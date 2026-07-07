SELECT
s.transaction_id,
s.product_id
FROM `gcp-project-usecase.retail_bronze.sales_raw_enterprise` s
LEFT JOIN
`gcp-project-usecase.retail_bronze.products_raw` p
ON s.product_id=p.product_id
WHERE p.product_id IS NULL;