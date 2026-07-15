SELECT 'CUSTOMERS' AS metric, COUNT(*) AS value
FROM `gcp-project-usecase.retail_gold.customer_360`

UNION ALL

SELECT 'STORES', COUNT(*)
FROM `gcp-project-usecase.retail_gold.store_performance`

UNION ALL

SELECT 'INVENTORY_ITEMS', COUNT(*)
FROM `gcp-project-usecase.retail_gold.inventory_optimization`

UNION ALL

SELECT 'RETURN_KPI_ROWS', COUNT(*)
FROM `gcp-project-usecase.retail_gold.returns_analytics`

UNION ALL

SELECT 'PROMOTION_KPI_ROWS', COUNT(*)
FROM `gcp-project-usecase.retail_gold.promotion_effectiveness`

UNION ALL

SELECT 'SUPPLY_CHAIN_ROWS', COUNT(*)
FROM `gcp-project-usecase.retail_gold.supply_chain_kpi`;