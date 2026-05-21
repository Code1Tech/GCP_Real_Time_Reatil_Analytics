from airflow import DAG

from airflow.providers.google.cloud.operators.bigquery import (
    BigQueryInsertJobOperator
)

from datetime import datetime

PROJECT_ID = "gcp-project-usecase"

default_args = {
    "owner": "retail-team",
    "start_date": datetime(2026,1,1),
}

with DAG(
    dag_id="retail_pipeline",
    default_args=default_args,
    schedule_interval="*/15 * * * *",
    catchup=False
) as dag:

    silver_layer = BigQueryInsertJobOperator(

        task_id="sales_clean_layer",

        configuration={
            "query": {
                "query": f"""

CREATE OR REPLACE TABLE
`{PROJECT_ID}.retail_silver.sales_clean`

PARTITION BY DATE(transaction_ts)

CLUSTER BY store_id, product_id

AS

SELECT

transaction_id,
transaction_ts,
DATE(transaction_ts) AS transaction_date,
store_id,
region,
product_id,
product_name,
category,
customer_id,
quantity,
unit_price,
discount_amount,
quantity * unit_price AS gross_sales,
(quantity * unit_price)
- discount_amount AS net_sales,
payment_method,
ingestion_ts

FROM `{PROJECT_ID}.retail_bronze.sales_raw`

WHERE quantity > 0

QUALIFY ROW_NUMBER() OVER(
PARTITION BY transaction_id
ORDER BY ingestion_ts DESC
)=1

                """,
                "useLegacySql": False
            }
        }
    )

    gold_layer = BigQueryInsertJobOperator(

        task_id="daily_sales_kpi_layer",

        configuration={
            "query": {
                "query": f"""

CREATE OR REPLACE TABLE
`{PROJECT_ID}.retail_gold.daily_sales_kpi`

AS

SELECT

transaction_date,
region,
store_id,

SUM(net_sales) AS revenue,

SUM(quantity) AS units_sold,

COUNT(DISTINCT transaction_id)
AS total_transactions,

AVG(net_sales)
AS avg_transaction_value

FROM
`{PROJECT_ID}.retail_silver.sales_clean`

GROUP BY 1,2,3

                """,
                "useLegacySql": False
            }
        }
    )

    silver_layer >> gold_layer