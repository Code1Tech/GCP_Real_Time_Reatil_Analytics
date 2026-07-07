SELECT *
FROM `gcp-project-usecase.retail_bronze.sales_raw_enterprise`
WHERE quantity<=0
OR total_amount<=0;