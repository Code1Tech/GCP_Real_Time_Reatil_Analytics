SELECT 'SALES' AS event_type, COUNT(*) AS event_count
FROM `gcp-project-usecase.retail_bronze.sales_events_raw`

UNION ALL

SELECT 'INVENTORY', COUNT(*)
FROM `gcp-project-usecase.retail_bronze.inventory_events_raw`

UNION ALL

SELECT 'RETURN', COUNT(*)
FROM `gcp-project-usecase.retail_bronze.return_events_raw`

UNION ALL

SELECT 'PROMOTION', COUNT(*)
FROM `gcp-project-usecase.retail_bronze.promotion_events_raw`

UNION ALL

SELECT 'CUSTOMER', COUNT(*)
FROM `gcp-project-usecase.retail_bronze.customer_events_raw`

UNION ALL

SELECT 'WAREHOUSE', COUNT(*)
FROM `gcp-project-usecase.retail_bronze.warehouse_events_raw`

ORDER BY event_count DESC;