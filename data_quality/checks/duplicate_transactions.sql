SELECT
    transaction_id,
    COUNT(*) AS duplicate_count
FROM `gcp-project-usecase.retail_bronze.sales_raw_enterprise`
GROUP BY transaction_id
HAVING COUNT(*) > 1;