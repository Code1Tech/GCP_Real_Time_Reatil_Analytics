import argparse
import json
from datetime import UTC, datetime
from typing import Any, Iterable

import apache_beam as beam
from apache_beam.io.gcp.bigquery import BigQueryDisposition
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


class ParseAndRouteEvent(beam.DoFn):
    def process(self, message: bytes) -> Iterable[Any]:
        raw_payload = message.decode("utf-8")

        try:
            event = json.loads(raw_payload)
            event_type = event.get("event_type")

            if not event.get("event_id"):
                raise ValueError("event_id is missing")

            if not event_type:
                raise ValueError("event_type is missing")

            event["ingestion_timestamp"] = datetime.now(UTC).isoformat()

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
                raise ValueError(f"Unsupported event_type: {event_type}")

        except Exception as exc:
            yield TaggedOutput(
                FAILED_TAG,
                {
                    "failed_timestamp": datetime.now(UTC).isoformat(),
                    "event_type": "UNKNOWN",
                    "raw_payload": raw_payload,
                    "error_message": str(exc),
                    "dataflow_job_name": "enterprise-retail-event-router",
                },
            )


def write_to_bigquery(
    collection: beam.PCollection,
    table_name: str,
) -> None:
    collection | f"Write {table_name}" >> beam.io.WriteToBigQuery(
        table=f"{PROJECT_ID}:{BRONZE_DATASET}.{table_name}",
        create_disposition=BigQueryDisposition.CREATE_NEVER,
        write_disposition=BigQueryDisposition.WRITE_APPEND,
        method=beam.io.WriteToBigQuery.Method.STREAMING_INSERTS,
        insert_retry_strategy="RETRY_ON_TRANSIENT_ERROR",
    )


def run() -> None:
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--input_subscription",
        required=True,
    )

    known_args, pipeline_args = parser.parse_known_args()

    pipeline_options = PipelineOptions(
        pipeline_args,
        streaming=True,
        save_main_session=True,
    )

    with beam.Pipeline(options=pipeline_options) as pipeline:
        routed = (
            pipeline
            | "Read enterprise retail events"
            >> beam.io.ReadFromPubSub(
                subscription=known_args.input_subscription
            )
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

        write_to_bigquery(routed[SALES_TAG], "sales_events_raw")
        write_to_bigquery(routed[INVENTORY_TAG], "inventory_events_raw")
        write_to_bigquery(routed[RETURN_TAG], "return_events_raw")
        write_to_bigquery(routed[PROMOTION_TAG], "promotion_events_raw")
        write_to_bigquery(routed[CUSTOMER_TAG], "customer_events_raw")
        write_to_bigquery(routed[WAREHOUSE_TAG], "warehouse_events_raw")
        write_to_bigquery(routed[FAILED_TAG], "failed_retail_events")


if __name__ == "__main__":
    run()