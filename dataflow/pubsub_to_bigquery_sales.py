import json
import argparse
import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions

TABLE_SCHEMA = {
    "fields": [
        {"name": "transaction_id", "type": "STRING", "mode": "REQUIRED"},
        {"name": "transaction_timestamp", "type": "TIMESTAMP", "mode": "NULLABLE"},
        {"name": "customer_id", "type": "STRING", "mode": "NULLABLE"},
        {"name": "product_id", "type": "STRING", "mode": "NULLABLE"},
        {"name": "store_id", "type": "STRING", "mode": "NULLABLE"},
        {"name": "quantity", "type": "INTEGER", "mode": "NULLABLE"},
        {"name": "unit_price", "type": "NUMERIC", "mode": "NULLABLE"},
        {"name": "discount", "type": "NUMERIC", "mode": "NULLABLE"},
        {"name": "tax", "type": "NUMERIC", "mode": "NULLABLE"},
        {"name": "payment_method", "type": "STRING", "mode": "NULLABLE"},
        {"name": "salesperson", "type": "STRING", "mode": "NULLABLE"},
        {"name": "total_amount", "type": "NUMERIC", "mode": "NULLABLE"},
    ]
}

class ParseMessage(beam.DoFn):
    def process(self, message):
        yield json.loads(message.decode("utf-8"))

def run():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_subscription", required=True)
    parser.add_argument("--output_table", required=True)
    known_args, pipeline_args = parser.parse_known_args()

    options = PipelineOptions(
        pipeline_args,
        streaming=True,
        save_main_session=True
    )

    with beam.Pipeline(options=options) as p:
        (
            p
            | "ReadFromPubSub" >> beam.io.ReadFromPubSub(
                subscription=known_args.input_subscription
            )
            | "ParseJson" >> beam.ParDo(ParseMessage())
            | "WriteToBigQuery" >> beam.io.WriteToBigQuery(
                known_args.output_table,
                schema=TABLE_SCHEMA,
                write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
                create_disposition=beam.io.BigQueryDisposition.CREATE_NEVER,
            )
        )

if __name__ == "__main__":
    run()