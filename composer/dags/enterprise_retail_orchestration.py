from __future__ import annotations

from datetime import datetime, timedelta
from pathlib import Path

from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import (
    BigQueryCheckOperator,
    BigQueryInsertJobOperator,
)
from airflow.utils.task_group import TaskGroup


PROJECT_ID = "gcp-project-usecase"
LOCATION = "US"

DAG_FOLDER = Path("/home/airflow/gcs/dags")
SQL_FOLDER = DAG_FOLDER / "sql"


def read_sql(relative_path: str) -> str:
    sql_path = SQL_FOLDER / relative_path
    return sql_path.read_text(encoding="utf-8")


default_args = {
    "owner": "retail-data-platform",
    "depends_on_past": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}


with DAG(
    dag_id="enterprise_retail_bronze_silver_gold",
    description="Orchestrates advanced retail Silver and Gold models",
    default_args=default_args,
    start_date=datetime(2026, 7, 1),
    schedule=None,
    catchup=False,
    max_active_runs=1,
    tags=["retail", "bigquery", "silver", "gold"],
) as dag:

    check_bronze_sales = BigQueryCheckOperator(
        task_id="check_bronze_sales",
        sql="""
        SELECT COUNT(*) > 0
        FROM `gcp-project-usecase.retail_bronze.sales_raw_enterprise`
        """,
        use_legacy_sql=False,
        location=LOCATION,
    )

    check_streaming_sales = BigQueryCheckOperator(
        task_id="check_streaming_sales",
        sql="""
        SELECT COUNT(*) > 0
        FROM `gcp-project-usecase.retail_bronze.sales_events_raw`
        """,
        use_legacy_sql=False,
        location=LOCATION,
    )

    build_advanced_silver = BigQueryInsertJobOperator(
        task_id="build_advanced_silver",
        configuration={
            "query": {
                "query": read_sql(
                    "silver/advanced_retail_models.sql"
                ),
                "useLegacySql": False,
                "priority": "BATCH",
            }
        },
        location=LOCATION,
    )

    validate_silver_sales = BigQueryCheckOperator(
        task_id="validate_silver_sales",
        sql="""
        SELECT
          COUNT(*) > 0
          AND COUNTIF(quantity <= 0) = 0
          AND COUNTIF(unit_price <= 0) = 0
        FROM `gcp-project-usecase.retail_silver.sales_unified_clean`
        """,
        use_legacy_sql=False,
        location=LOCATION,
    )

    with TaskGroup(group_id="build_gold") as build_gold:

        customer_360 = BigQueryInsertJobOperator(
            task_id="customer_360",
            configuration={
                "query": {
                    "query": read_sql("gold/01_customer_360.sql"),
                    "useLegacySql": False,
                }
            },
            location=LOCATION,
        )

        store_performance = BigQueryInsertJobOperator(
            task_id="store_performance",
            configuration={
                "query": {
                    "query": read_sql("gold/02_store_performance.sql"),
                    "useLegacySql": False,
                }
            },
            location=LOCATION,
        )

        inventory_optimization = BigQueryInsertJobOperator(
            task_id="inventory_optimization",
            configuration={
                "query": {
                    "query": read_sql("gold/03_inventory_optimization.sql"),
                    "useLegacySql": False,
                }
            },
            location=LOCATION,
        )

        returns_analytics = BigQueryInsertJobOperator(
            task_id="returns_analytics",
            configuration={
                "query": {
                    "query": read_sql("gold/04_returns_analytics.sql"),
                    "useLegacySql": False,
                }
            },
            location=LOCATION,
        )

        promotion_effectiveness = BigQueryInsertJobOperator(
            task_id="promotion_effectiveness",
            configuration={
                "query": {
                    "query": read_sql("gold/05_promotion_effectiveness.sql"),
                    "useLegacySql": False,
                }
            },
            location=LOCATION,
        )

        supply_chain_kpi = BigQueryInsertJobOperator(
            task_id="supply_chain_kpi",
            configuration={
                "query": {
                    "query": read_sql("gold/06_supply_chain_kpi.sql"),
                    "useLegacySql": False,
                }
            },
            location=LOCATION,
        )

        realtime_executive_kpi = BigQueryInsertJobOperator(
            task_id="realtime_executive_kpi",
            configuration={
                "query": {
                    "query": read_sql("gold/07_realtime_executive_kpi.sql"),
                    "useLegacySql": False,
                }
            },
            location=LOCATION,
        )

    validate_gold = BigQueryCheckOperator(
        task_id="validate_gold",
        sql="""
        SELECT
          (SELECT COUNT(*) FROM
            `gcp-project-usecase.retail_gold.customer_360`) > 0
          AND
          (SELECT COUNT(*) FROM
            `gcp-project-usecase.retail_gold.store_performance`) > 0
          AND
          (SELECT COUNT(*) FROM
            `gcp-project-usecase.retail_gold.inventory_optimization`) > 0
        """,
        use_legacy_sql=False,
        location=LOCATION,
    )
    check_bronze_sales >> check_streaming_sales
    check_streaming_sales >> build_advanced_silver
    build_advanced_silver >> validate_silver_sales

    validate_silver_sales >> customer_360
    customer_360 >> store_performance
    store_performance >> inventory_optimization
    inventory_optimization >> returns_analytics
    returns_analytics >> promotion_effectiveness
    promotion_effectiveness >> supply_chain_kpi
    supply_chain_kpi >> realtime_executive_kpi
    realtime_executive_kpi >> validate_gold
    