$PROJECT_ID="gcp-project-usecase"
$DATASET="retail_bronze"
$BUCKET="gs://gcp-retail-analytics-lake"

Write-Host "Loading Customers..."
bq load --replace --source_format=CSV --skip_leading_rows=1 `
$PROJECT_ID`:$DATASET.customers_raw `
$BUCKET/raw/customers/customers.csv

Write-Host "Loading Products..."
bq load --replace --source_format=CSV --skip_leading_rows=1 `
$PROJECT_ID`:$DATASET.products_raw `
$BUCKET/raw/products/products.csv

Write-Host "Loading Stores..."
bq load --replace --source_format=CSV --skip_leading_rows=1 `
$PROJECT_ID`:$DATASET.stores_raw `
$BUCKET/raw/stores/stores.csv

Write-Host "Loading Inventory..."
bq load --replace --source_format=CSV --skip_leading_rows=1 `
$PROJECT_ID`:$DATASET.inventory_raw_enterprise `
$BUCKET/raw/inventory/inventory.csv

Write-Host "Loading Promotions..."
bq load --replace --source_format=CSV --skip_leading_rows=1 `
$PROJECT_ID`:$DATASET.promotions_raw `
$BUCKET/raw/promotions/promotions.csv

Write-Host "Loading Returns..."
bq load --replace --source_format=CSV --skip_leading_rows=1 `
$PROJECT_ID`:$DATASET.returns_raw `
$BUCKET/raw/returns/returns.csv

Write-Host "Loading Sales..."
bq load --replace --source_format=CSV --skip_leading_rows=1 `
$PROJECT_ID`:$DATASET.sales_raw_enterprise `
$BUCKET/raw/sales/sales_10000.csv

Write-Host ""
Write-Host "========================================="
Write-Host " Bronze Layer Loaded Successfully"
Write-Host "========================================="