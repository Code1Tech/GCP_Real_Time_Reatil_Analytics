SELECT *
FROM `gcp-project-usecase.retail_bronze.sales_raw_enterprise`
WHERE

transaction_id IS NULL
OR customer_id IS NULL
OR product_id IS NULL
OR store_id IS NULL;