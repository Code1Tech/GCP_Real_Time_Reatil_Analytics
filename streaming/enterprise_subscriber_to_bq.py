import json
import time
from google.cloud import pubsub_v1
from google.cloud import bigquery

PROJECT_ID = "gcp-project-usecase"
SUBSCRIPTION_ID = "retail-sales-sub"
TABLE_ID = "gcp-project-usecase.retail_bronze.sales_raw_enterprise"

subscriber = pubsub_v1.SubscriberClient()
bq_client = bigquery.Client(project=PROJECT_ID)

subscription_path = subscriber.subscription_path(PROJECT_ID, SUBSCRIPTION_ID)

def callback(message):
    try:
        row = json.loads(message.data.decode("utf-8"))
        errors = bq_client.insert_rows_json(TABLE_ID, [row])

        if errors:
            print("BigQuery insert error:", errors)
            message.nack()
        else:
            print("Inserted:", row["transaction_id"])
            message.ack()

    except Exception as e:
        print("Subscriber error:", e)
        message.nack()

print("Listening on:", subscription_path)

streaming_pull_future = subscriber.subscribe(subscription_path, callback=callback)

try:
    while True:
        time.sleep(60)
except KeyboardInterrupt:
    streaming_pull_future.cancel()
    print("Subscriber stopped.")