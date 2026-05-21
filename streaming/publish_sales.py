import json
import uuid
import random
import time
from datetime import datetime
from google.cloud import pubsub_v1

PROJECT_ID = "gcp-project-usecase"
TOPIC_ID = "retail-sales-topic"

publisher = pubsub_v1.PublisherClient()

topic_path = publisher.topic_path(
    PROJECT_ID,
    TOPIC_ID
)

print("Publishing to:", topic_path)

products = [
    ("P001", "Running Shoes", "Footwear", 3000),
    ("P002", "Jeans", "Apparel", 2500),
    ("P003", "Smart Watch", "Electronics", 8000),
]

stores = [
    ("S001", "North"),
    ("S002", "South"),
    ("S003", "West"),
]

while True:

    product = random.choice(products)
    store = random.choice(stores)

    event = {
        "transaction_id": str(uuid.uuid4()),
        "transaction_ts": datetime.utcnow().isoformat(),
        "store_id": store[0],
        "region": store[1],
        "product_id": product[0],
        "product_name": product[1],
        "category": product[2],
        "customer_id": random.choice(["C001","C002","C003"]),
        "quantity": random.randint(1,5),
        "unit_price": product[3],
        "discount_amount": random.randint(0,300),
        "payment_method": random.choice(["CARD","UPI","CASH"]),
        "ingestion_ts": datetime.utcnow().isoformat()
    }

    future = publisher.publish(
    topic_path,
    json.dumps(event).encode("utf-8")
)

    message_id = future.result()

    print("Published message ID:", message_id)

    print(event)

    time.sleep(2)