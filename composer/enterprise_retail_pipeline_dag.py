from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from datetime import datetime

PROJECT_ID = "gcp-project-usecase"

default_args = {
    "owner": "retail-analytics",
    "start_date": datetime(2026, 1, 1),
    "retries": 1,
}

with DAG(
    dag_id="enterprise_retail_bronze_silver_gold_ai",
    default_args=default_args,
    schedule_interval="@daily",
    catchup=False,
    tags=["retail", "bigquery", "silver", "gold", "ai"],
) as dag:

    build_silver = BigQueryInsertJobOperator(
        task_id="build_silver_enterprise_sales_clean",
        configuration={
            "query": {
                "query": open("/home/airflow/gcs/dags/sql/enterprise_sales_clean.sql").read(),
                "useLegacySql": False,
            }
        },
    )

    build_gold = BigQueryInsertJobOperator(
        task_id="build_gold_enterprise_kpis",
        configuration={
            "query": {
                "query": open("/home/airflow/gcs/dags/sql/enterprise_kpis.sql").read(),
                "useLegacySql": False,
            }
        },
    )

    build_ai_features = BigQueryInsertJobOperator(
        task_id="build_ai_feature_tables",
        configuration={
            "query": {
                "query": open("/home/airflow/gcs/dags/sql/ai_kpi_features.sql").read(),
                "useLegacySql": False,
            }
        },
    )

    build_silver >> build_gold >> build_ai_features