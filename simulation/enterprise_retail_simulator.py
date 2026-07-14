import argparse
import json
import random
import time
import uuid
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal
from typing import Any

from google.cloud import pubsub_v1


PROJECT_ID = "gcp-project-usecase"
TOPIC_ID = "retail-events-topic"

CUSTOMERS = [f"C{i:04d}" for i in range(1, 1001)]
PRODUCTS = [f"P{i:04d}" for i in range(1, 501)]
STORES = [f"S{i:03d}" for i in range(1, 51)]
WAREHOUSES = ["WH-NORTH", "WH-SOUTH", "WH-EAST", "WH-WEST"]

PAYMENT_METHODS = ["UPI", "CARD", "CASH", "WALLET"]
RETURN_REASONS = [
    "Damaged",
    "Wrong Product",
    "Quality Issue",
    "Size Issue",
    "Changed Mind",
]
CUSTOMER_EVENT_TYPES = [
    "LOGIN",
    "PRODUCT_VIEW",
    "ADD_TO_CART",
    "REMOVE_FROM_CART",
    "CHECKOUT_STARTED",
]
CHANNELS = ["STORE", "WEB", "MOBILE_APP"]
DEVICES = ["MOBILE", "DESKTOP", "TABLET", "POS"]
LOYALTY_TIERS = ["Bronze", "Silver", "Gold", "Platinum"]
CATEGORIES = [
    "Fashion",
    "Footwear",
    "Electronics",
    "Beauty",
    "Sports",
]


def utc_now() -> str:
    return datetime.now(UTC).isoformat()


def json_default(value: Any) -> str:
    if isinstance(value, (datetime, date)):
        return value.isoformat()
    if isinstance(value, Decimal):
        return str(value)
    raise TypeError(f"Unsupported JSON type: {type(value)}")


def base_event(event_type: str) -> dict[str, Any]:
    return {
        "event_id": str(uuid.uuid4()),
        "event_type": event_type,
        "event_timestamp": utc_now(),
        "ingestion_timestamp": utc_now(),
    }


def create_sales_event() -> dict[str, Any]:
    event = base_event("SALES")

    quantity = random.randint(1, 5)
    unit_price = random.choice([799, 1299, 2499, 3499, 7999, 15999])
    gross_amount = quantity * unit_price
    discount = round(gross_amount * random.uniform(0.0, 0.25), 2)
    tax = round((gross_amount - discount) * 0.18, 2)
    total_amount = round(gross_amount - discount + tax, 2)

    event.update(
        {
            "transaction_id": str(uuid.uuid4()),
            "customer_id": random.choice(CUSTOMERS),
            "product_id": random.choice(PRODUCTS),
            "store_id": random.choice(STORES),
            "quantity": quantity,
            "unit_price": unit_price,
            "discount": discount,
            "tax": tax,
            "payment_method": random.choice(PAYMENT_METHODS),
            "salesperson": f"EMP{random.randint(1, 300):03d}",
            "total_amount": total_amount,
        }
    )

    return event


def create_inventory_event() -> dict[str, Any]:
    event = base_event("INVENTORY")

    previous_stock = random.randint(0, 500)
    change_reason = random.choice(
        [
            "SALE",
            "RETURN",
            "REPLENISHMENT",
            "STOCK_ADJUSTMENT",
            "DAMAGE",
        ]
    )

    if change_reason in {"SALE", "DAMAGE"}:
        quantity_change = -random.randint(1, min(max(previous_stock, 1), 10))
    else:
        quantity_change = random.randint(1, 100)

    current_stock = max(previous_stock + quantity_change, 0)

    event.update(
        {
            "inventory_id": f"INV-{uuid.uuid4()}",
            "store_id": random.choice(STORES),
            "product_id": random.choice(PRODUCTS),
            "previous_stock": previous_stock,
            "quantity_change": quantity_change,
            "current_stock": current_stock,
            "warehouse_stock": random.randint(50, 2500),
            "reorder_level": random.randint(20, 100),
            "change_reason": change_reason,
        }
    )

    return event


def create_return_event() -> dict[str, Any]:
    event = base_event("RETURN")

    quantity = random.randint(1, 3)
    refund_amount = round(quantity * random.uniform(500, 10000), 2)

    event.update(
        {
            "return_id": f"RET-{uuid.uuid4()}",
            "transaction_id": str(uuid.uuid4()),
            "customer_id": random.choice(CUSTOMERS),
            "product_id": random.choice(PRODUCTS),
            "store_id": random.choice(STORES),
            "return_quantity": quantity,
            "refund_amount": refund_amount,
            "return_reason": random.choice(RETURN_REASONS),
            "return_status": random.choice(
                ["REQUESTED", "APPROVED", "REFUNDED", "REJECTED"]
            ),
        }
    )

    return event


def create_promotion_event() -> dict[str, Any]:
    event = base_event("PROMOTION")

    campaign_id = f"CMP-{random.randint(1, 999):03d}"
    start = datetime.now(UTC).date()
    end = start + timedelta(days=random.randint(7, 45))

    event.update(
        {
            "campaign_id": campaign_id,
            "campaign_name": f"Retail Campaign {campaign_id}",
            "product_id": random.choice(PRODUCTS),
            "category": random.choice(CATEGORIES),
            "region": random.choice(["North", "South", "East", "West"]),
            "discount_percent": random.choice([5, 10, 15, 20, 25, 30]),
            "campaign_status": random.choice(
                ["PLANNED", "ACTIVE", "PAUSED", "COMPLETED"]
            ),
            "start_date": start.isoformat(),
            "end_date": end.isoformat(),
        }
    )

    return event


def create_customer_event() -> dict[str, Any]:
    event = base_event("CUSTOMER")

    event.update(
        {
            "customer_id": random.choice(CUSTOMERS),
            "customer_event_type": random.choice(CUSTOMER_EVENT_TYPES),
            "channel": random.choice(CHANNELS),
            "device_type": random.choice(DEVICES),
            "store_id": random.choice(STORES),
            "product_id": random.choice(PRODUCTS),
            "session_id": str(uuid.uuid4()),
            "loyalty_tier": random.choice(LOYALTY_TIERS),
        }
    )

    return event


def create_warehouse_event() -> dict[str, Any]:
    event = base_event("WAREHOUSE")

    warehouse_event_type = random.choice(
        [
            "RECEIPT",
            "STORE_TRANSFER",
            "DISPATCH",
            "QUALITY_HOLD",
        ]
    )

    event.update(
        {
            "warehouse_event_id": f"WH-EVT-{uuid.uuid4()}",
            "warehouse_id": random.choice(WAREHOUSES),
            "destination_store_id": random.choice(STORES),
            "product_id": random.choice(PRODUCTS),
            "quantity": random.randint(10, 500),
            "warehouse_event_type": warehouse_event_type,
            "shipment_status": random.choice(
                ["CREATED", "IN_TRANSIT", "DELIVERED", "DELAYED"]
            ),
            "expected_delivery_date": (
                datetime.now(UTC).date()
                + timedelta(days=random.randint(1, 10))
            ).isoformat(),
        }
    )

    return event


EVENT_GENERATORS = {
    "SALES": create_sales_event,
    "INVENTORY": create_inventory_event,
    "RETURN": create_return_event,
    "PROMOTION": create_promotion_event,
    "CUSTOMER": create_customer_event,
    "WAREHOUSE": create_warehouse_event,
}

EVENT_WEIGHTS = {
    "SALES": 45,
    "INVENTORY": 20,
    "CUSTOMER": 15,
    "RETURN": 8,
    "PROMOTION": 5,
    "WAREHOUSE": 7,
}


def choose_event_type() -> str:
    event_types = list(EVENT_WEIGHTS.keys())
    weights = list(EVENT_WEIGHTS.values())
    return random.choices(event_types, weights=weights, k=1)[0]


def publish_event(
    publisher: pubsub_v1.PublisherClient,
    topic_path: str,
    event: dict[str, Any],
) -> None:
    payload = json.dumps(event, default=json_default).encode("utf-8")

    future = publisher.publish(
        topic_path,
        payload,
        event_type=event["event_type"],
    )

    message_id = future.result(timeout=30)

    print(
        f"Published event_type={event['event_type']} "
        f"message_id={message_id} "
        f"event_id={event['event_id']}"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--interval-seconds",
        type=float,
        default=2.0,
        help="Delay between generated events.",
    )
    parser.add_argument(
        "--event-type",
        choices=[*EVENT_GENERATORS.keys(), "MIXED"],
        default="MIXED",
        help="Generate one event type or a weighted mixed stream.",
    )
    parser.add_argument(
        "--max-events",
        type=int,
        default=0,
        help="Stop after this many events. Zero means run forever.",
    )

    args = parser.parse_args()

    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(PROJECT_ID, TOPIC_ID)

    print(f"Publishing enterprise retail events to {topic_path}")
    print(f"Mode: {args.event_type}")

    published_count = 0

    try:
        while True:
            event_type = (
                choose_event_type()
                if args.event_type == "MIXED"
                else args.event_type
            )

            event = EVENT_GENERATORS[event_type]()
            publish_event(publisher, topic_path, event)

            published_count += 1

            if args.max_events > 0 and published_count >= args.max_events:
                break

            time.sleep(args.interval_seconds)

    except KeyboardInterrupt:
        print("\nSimulator stopped.")

    finally:
        publisher.stop()
        print(f"Total events published: {published_count}")


if __name__ == "__main__":
    main()