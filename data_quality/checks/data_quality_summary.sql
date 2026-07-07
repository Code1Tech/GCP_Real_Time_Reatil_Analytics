SELECT

(SELECT COUNT(*) FROM `gcp-project-usecase.retail_bronze.sales_raw_enterprise`) AS TotalSales,

(SELECT COUNT(*) FROM `gcp-project-usecase.retail_bronze.customers_raw`) AS Customers,

(SELECT COUNT(*) FROM `gcp-project-usecase.retail_bronze.products_raw`) AS Products,

(SELECT COUNT(*) FROM `gcp-project-usecase.retail_bronze.inventory_raw_enterprise`) AS InventoryRecords;