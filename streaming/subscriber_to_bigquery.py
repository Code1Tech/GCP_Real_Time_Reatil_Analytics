import json
from google.cloud import pubsub_v1
from google.cloud import bigquery

PROJECT_ID = "gcp-project-usecase"

SUBSCRIPTION_ID = "retail-sales-sub"

TABLE_ID = "gcp-project-usecase.retail_bronze.sales_raw"

subscriber = pubsub_v1.SubscriberClient()

bq_client = bigquery.Client()

subscription_path = subscriber.subscription_path(
    PROJECT_ID,
    SUBSCRIPTION_ID
)

def callback(message):

    data = json.loads(
        message.data.decode("utf-8")
    )

    errors = bq_client.insert_rows_json(
        TABLE_ID,
        [data]
    )

    if not errors:
        print("Inserted:", data["transaction_id"])
        message.ack()
    else:
        print(errors)
        message.nack()

subscriber.subscribe(
    subscription_path,
    callback=callback
)

print("Listening for messages...")

import time

while True:
    time.sleep(60)