import json
import random
import time
import uuid
from datetime import datetime, UTC
from google.cloud import pubsub_v1

PROJECT_ID = "gcp-project-usecase"
TOPIC_ID = "retail-sales-topic"

publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(PROJECT_ID, TOPIC_ID)

products = [
    {"product_id": "P0001", "product_name": "UrbanWear Shirts 1", "category": "Fashion", "unit_price": 1299},
    {"product_id": "P0002", "product_name": "StepUp Running Shoes 2", "category": "Footwear", "unit_price": 3499},
    {"product_id": "P0003", "product_name": "TechNova Smart Watch 3", "category": "Electronics", "unit_price": 7999},
]

stores = [
    {"store_id": "S001", "region": "North"},
    {"store_id": "S002", "region": "South"},
    {"store_id": "S003", "region": "West"},
]

customers = [f"C{i:04d}" for i in range(1, 1001)]

print("Publishing to:", topic_path)

while True:
    product = random.choice(products)
    store = random.choice(stores)
    quantity = random.randint(1, 5)
    gross_amount = quantity * product["unit_price"]
    discount = round(gross_amount * random.uniform(0, 0.20), 2)
    tax = round((gross_amount - discount) * 0.18, 2)
    total_amount = round(gross_amount - discount + tax, 2)

    event = {
        "transaction_id": str(uuid.uuid4()),
        "transaction_timestamp": datetime.now(UTC).isoformat(),
        "customer_id": random.choice(customers),
        "product_id": product["product_id"],
        "store_id": store["store_id"],
        "quantity": quantity,
        "unit_price": product["unit_price"],
        "discount": discount,
        "tax": tax,
        "payment_method": random.choice(["UPI", "CARD", "CASH", "WALLET"]),
        "salesperson": f"EMP{random.randint(1,300):03d}",
        "total_amount": total_amount
    }

    future = publisher.publish(topic_path, json.dumps(event).encode("utf-8"))
    print("Published:", future.result(), event)

    time.sleep(2)