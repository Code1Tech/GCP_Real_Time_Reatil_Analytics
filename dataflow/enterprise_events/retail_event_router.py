import argparse
import json
import logging
from datetime import UTC, datetime
from typing import Any, Iterable

import apache_beam as beam
from apache_beam.io.gcp.bigquery import BigQueryDisposition
from apache_beam.io.gcp.bigquery_tools import RetryStrategy
from apache_beam.metrics.metric import Metrics
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.pvalue import TaggedOutput


PROJECT_ID = "gcp-project-usecase"
BRONZE_DATASET = "retail_bronze"

SALES_TAG = "sales"
INVENTORY_TAG = "inventory"
RETURN_TAG = "returns"
PROMOTION_TAG = "promotions"
CUSTOMER_TAG = "customers"
WAREHOUSE_TAG = "warehouse"
FAILED_TAG = "failed"


SCHEMAS = {
    "sales_events_raw": (
        "event_id:STRING,event_type:STRING,event_timestamp:TIMESTAMP,"
        "transaction_id:STRING,customer_id:STRING,product_id:STRING,"
        "store_id:STRING,quantity:INTEGER,unit_price:NUMERIC,"
        "discount:NUMERIC,tax:NUMERIC,payment_method:STRING,"
        "salesperson:STRING,total_amount:NUMERIC,"
        "ingestion_timestamp:TIMESTAMP"
    ),
    "inventory_events_raw": (
        "event_id:STRING,event_type:STRING,event_timestamp:TIMESTAMP,"
        "inventory_id:STRING,store_id:STRING,product_id:STRING,"
        "previous_stock:INTEGER,quantity_change:INTEGER,"
        "current_stock:INTEGER,warehouse_stock:INTEGER,"
        "reorder_level:INTEGER,change_reason:STRING,"
        "ingestion_timestamp:TIMESTAMP"
    ),
    "return_events_raw": (
        "event_id:STRING,event_type:STRING,event_timestamp:TIMESTAMP,"
        "return_id:STRING,transaction_id:STRING,customer_id:STRING,"
        "product_id:STRING,store_id:STRING,return_quantity:INTEGER,"
        "refund_amount:NUMERIC,return_reason:STRING,"
        "return_status:STRING,ingestion_timestamp:TIMESTAMP"
    ),
    "promotion_events_raw": (
        "event_id:STRING,event_type:STRING,event_timestamp:TIMESTAMP,"
        "campaign_id:STRING,campaign_name:STRING,product_id:STRING,"
        "category:STRING,region:STRING,discount_percent:NUMERIC,"
        "campaign_status:STRING,start_date:DATE,end_date:DATE,"
        "ingestion_timestamp:TIMESTAMP"
    ),
    "customer_events_raw": (
        "event_id:STRING,event_type:STRING,event_timestamp:TIMESTAMP,"
        "customer_id:STRING,customer_event_type:STRING,channel:STRING,"
        "device_type:STRING,store_id:STRING,product_id:STRING,"
        "session_id:STRING,loyalty_tier:STRING,"
        "ingestion_timestamp:TIMESTAMP"
    ),
    "warehouse_events_raw": (
        "event_id:STRING,event_type:STRING,event_timestamp:TIMESTAMP,"
        "warehouse_event_id:STRING,warehouse_id:STRING,"
        "destination_store_id:STRING,product_id:STRING,"
        "quantity:INTEGER,warehouse_event_type:STRING,"
        "shipment_status:STRING,expected_delivery_date:DATE,"
        "ingestion_timestamp:TIMESTAMP"
    ),
    "failed_retail_events": (
        "failed_timestamp:TIMESTAMP,event_type:STRING,"
        "raw_payload:STRING,error_message:STRING,"
        "dataflow_job_name:STRING"
    ),
}


class ParseAndRouteEvent(beam.DoFn):
    def __init__(self) -> None:
        self.received = Metrics.counter(self.__class__, "events_received")
        self.parsed = Metrics.counter(self.__class__, "events_parsed")
        self.failed = Metrics.counter(self.__class__, "events_failed")

    def process(self, message: bytes) -> Iterable[Any]:
        self.received.inc()

        raw_payload = (
            message.decode("utf-8")
            if isinstance(message, bytes)
            else str(message)
        )

        event_type = "UNKNOWN"

        try:
            event = json.loads(raw_payload)
            event_type = str(event.get("event_type", "")).upper()

            if not event.get("event_id"):
                raise ValueError("event_id is missing")

            if not event_type:
                raise ValueError("event_type is missing")

            event["event_type"] = event_type
            event["ingestion_timestamp"] = datetime.now(UTC).isoformat()

            logging.info(
                "Routing event_id=%s event_type=%s",
                event["event_id"],
                event_type,
            )

            self.parsed.inc()

            if event_type == "SALES":
                yield TaggedOutput(SALES_TAG, event)
            elif event_type == "INVENTORY":
                yield TaggedOutput(INVENTORY_TAG, event)
            elif event_type == "RETURN":
                yield TaggedOutput(RETURN_TAG, event)
            elif event_type == "PROMOTION":
                yield TaggedOutput(PROMOTION_TAG, event)
            elif event_type == "CUSTOMER":
                yield TaggedOutput(CUSTOMER_TAG, event)
            elif event_type == "WAREHOUSE":
                yield TaggedOutput(WAREHOUSE_TAG, event)
            else:
                raise ValueError(
                    f"Unsupported event_type: {event_type}"
                )

        except Exception as exc:
            self.failed.inc()

            logging.exception(
                "Unable to process event. event_type=%s payload=%s",
                event_type,
                raw_payload,
            )

            yield TaggedOutput(
                FAILED_TAG,
                {
                    "failed_timestamp": datetime.now(UTC).isoformat(),
                    "event_type": event_type,
                    "raw_payload": raw_payload,
                    "error_message": str(exc),
                    "dataflow_job_name":
                        "enterprise-retail-event-router",
                },
            )


def write_to_bigquery(
    collection: beam.PCollection,
    table_name: str,
) -> beam.io.gcp.bigquery.WriteResult:
    return (
        collection
        | f"Write {table_name}"
        >> beam.io.WriteToBigQuery(
            table=f"{PROJECT_ID}:{BRONZE_DATASET}.{table_name}",
            schema=SCHEMAS[table_name],
            create_disposition=BigQueryDisposition.CREATE_NEVER,
            write_disposition=BigQueryDisposition.WRITE_APPEND,
            method=beam.io.WriteToBigQuery.Method.STREAMING_INSERTS,
            insert_retry_strategy=(
                RetryStrategy.RETRY_ON_TRANSIENT_ERROR
            ),
            ignore_unknown_columns=False,
        )
    )


def run() -> None:
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--input_subscription",
        required=True,
    )

    known_args, pipeline_args = parser.parse_known_args()

    options = PipelineOptions(
        pipeline_args,
        streaming=True,
        save_main_session=True,
    )

    with beam.Pipeline(options=options) as pipeline:
        messages = (
            pipeline
            | "Read enterprise retail events"
            >> beam.io.ReadFromPubSub(
                subscription=known_args.input_subscription,
                with_attributes=False,
            )
        )

        routed = (
            messages
            | "Parse and route events"
            >> beam.ParDo(ParseAndRouteEvent()).with_outputs(
                SALES_TAG,
                INVENTORY_TAG,
                RETURN_TAG,
                PROMOTION_TAG,
                CUSTOMER_TAG,
                WAREHOUSE_TAG,
                FAILED_TAG,
            )
        )

        write_to_bigquery(
            routed[SALES_TAG],
            "sales_events_raw",
        )
        write_to_bigquery(
            routed[INVENTORY_TAG],
            "inventory_events_raw",
        )
        write_to_bigquery(
            routed[RETURN_TAG],
            "return_events_raw",
        )
        write_to_bigquery(
            routed[PROMOTION_TAG],
            "promotion_events_raw",
        )
        write_to_bigquery(
            routed[CUSTOMER_TAG],
            "customer_events_raw",
        )
        write_to_bigquery(
            routed[WAREHOUSE_TAG],
            "warehouse_events_raw",
        )
        write_to_bigquery(
            routed[FAILED_TAG],
            "failed_retail_events",
        )


if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)
    run()