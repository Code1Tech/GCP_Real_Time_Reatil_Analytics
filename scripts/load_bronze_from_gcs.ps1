$PROJECT_ID="gcp-project-usecase"
$DATASET="retail_bronze"
$BUCKET="gs://gcp-retail-analytics-lake"

bq load --source_format=CSV --skip_leading_rows=1 $PROJECT_ID`:$DATASET.customers_raw $BUCKET/raw/customers/customers.csv

bq load --source_format=CSV --skip_leading_rows=1 $PROJECT_ID`:$DATASET.products_raw $BUCKET/raw/products/products.csv

bq load --source_format=CSV --skip_leading_rows=1 $PROJECT_ID`:$DATASET.stores_raw $BUCKET/raw/stores/stores.csv

bq load --source_format=CSV --skip_leading_rows=1 $PROJECT_ID`:$DATASET.inventory_raw_enterprise $BUCKET/raw/inventory/inventory.csv

bq load --source_format=CSV --skip_leading_rows=1 $PROJECT_ID`:$DATASET.promotions_raw $BUCKET/raw/promotions/promotions.csv

bq load --source_format=CSV --skip_leading_rows=1 $PROJECT_ID`:$DATASET.returns_raw $BUCKET/raw/returns/returns.csv

bq load --source_format=CSV --skip_leading_rows=1 $PROJECT_ID`:$DATASET.sales_raw_enterprise $BUCKET/raw/sales/sales_10000.csv

Write-Host "Bronze tables loaded from GCS successfully."