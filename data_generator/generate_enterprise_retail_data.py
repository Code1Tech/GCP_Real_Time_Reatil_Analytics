import csv
import random
import uuid
from datetime import datetime, timedelta

random.seed(42)

CUSTOMERS = 1000
PRODUCTS = 500
STORES = 50
SALES = 10000
INVENTORY = 2000
RETURNS_RATE = 0.07

cities = [
    ("Delhi", "Delhi", "North"),
    ("Mumbai", "Maharashtra", "West"),
    ("Bengaluru", "Karnataka", "South"),
    ("Hyderabad", "Telangana", "South"),
    ("Pune", "Maharashtra", "West"),
    ("Chennai", "Tamil Nadu", "South"),
    ("Kolkata", "West Bengal", "East"),
    ("Ahmedabad", "Gujarat", "West"),
]

categories = {
    "Fashion": ["Shirts", "Jeans", "Jackets"],
    "Footwear": ["Running Shoes", "Sandals", "Sports Shoes"],
    "Electronics": ["Mobile", "Laptop", "Smart Watch"],
    "Beauty": ["Skincare", "Makeup", "Perfume"],
    "Sports": ["Gym Equipment", "Yoga Mat", "Fitness Band"],
}

brands = ["UrbanWear", "StepUp", "TechNova", "GlowCare", "FitPro", "DailyStyle"]
loyalty_tiers = ["Bronze", "Silver", "Gold", "Platinum"]
payment_methods = ["UPI", "CARD", "CASH", "WALLET"]
genders = ["Male", "Female", "Other"]
store_types = ["Mall", "High Street", "Airport", "Outlet"]
return_reasons = ["Size Issue", "Damaged", "Wrong Product", "Quality Issue", "Changed Mind"]

def write_csv(path, rows, headers):
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=headers)
        writer.writeheader()
        writer.writerows(rows)

customers = []
for i in range(1, CUSTOMERS + 1):
    city, state, region = random.choice(cities)
    customers.append({
        "customer_id": f"C{i:04d}",
        "customer_name": f"Customer {i}",
        "gender": random.choice(genders),
        "age": random.randint(18, 65),
        "city": city,
        "state": state,
        "loyalty_tier": random.choice(loyalty_tiers),
        "joining_date": (datetime.now() - timedelta(days=random.randint(30, 1500))).date(),
        "email": f"customer{i}@example.com",
        "phone": f"9{random.randint(100000000,999999999)}"
    })

products = []
for i in range(1, PRODUCTS + 1):
    category = random.choice(list(categories.keys()))
    sub_category = random.choice(categories[category])
    cost_price = random.randint(300, 20000)
    margin = random.uniform(1.2, 2.2)
    selling_price = round(cost_price * margin, 2)

    products.append({
        "product_id": f"P{i:04d}",
        "product_name": f"{random.choice(brands)} {sub_category} {i}",
        "category": category,
        "sub_category": sub_category,
        "brand": random.choice(brands),
        "cost_price": cost_price,
        "selling_price": selling_price,
        "supplier": f"Supplier {random.randint(1, 50)}",
        "reorder_level": random.randint(20, 100)
    })

stores = []
for i in range(1, STORES + 1):
    city, state, region = random.choice(cities)
    stores.append({
        "store_id": f"S{i:03d}",
        "store_name": f"Retail Store {i}",
        "city": city,
        "state": state,
        "region": region,
        "store_type": random.choice(store_types),
        "opening_date": (datetime.now() - timedelta(days=random.randint(200, 3000))).date()
    })

inventory = []
for i in range(1, INVENTORY + 1):
    store = random.choice(stores)
    product = random.choice(products)
    inventory.append({
        "inventory_id": f"I{i:05d}",
        "store_id": store["store_id"],
        "product_id": product["product_id"],
        "current_stock": random.randint(0, 500),
        "warehouse_stock": random.randint(100, 2000),
        "reorder_level": product["reorder_level"],
        "last_updated": datetime.now().isoformat()
    })

promotions = []
for i in range(1, 101):
    start = datetime.now() - timedelta(days=random.randint(1, 180))
    end = start + timedelta(days=random.randint(7, 45))
    promotions.append({
        "campaign_id": f"PR{i:03d}",
        "campaign_name": f"Campaign {i}",
        "start_date": start.date(),
        "end_date": end.date(),
        "discount_percent": random.choice([5, 10, 15, 20, 25, 30])
    })

sales = []
returns = []

for i in range(1, SALES + 1):
    customer = random.choice(customers)
    product = random.choice(products)
    store = random.choice(stores)
    quantity = random.randint(1, 5)
    unit_price = float(product["selling_price"])
    discount = round(unit_price * quantity * random.uniform(0, 0.25), 2)
    tax = round((unit_price * quantity - discount) * 0.18, 2)
    total_amount = round((unit_price * quantity - discount) + tax, 2)

    txn_id = str(uuid.uuid4())
    txn_date = datetime.now() - timedelta(days=random.randint(0, 365))

    sales.append({
        "transaction_id": txn_id,
        "transaction_timestamp": txn_date.isoformat(),
        "customer_id": customer["customer_id"],
        "product_id": product["product_id"],
        "store_id": store["store_id"],
        "quantity": quantity,
        "unit_price": unit_price,
        "discount": discount,
        "tax": tax,
        "payment_method": random.choice(payment_methods),
        "salesperson": f"EMP{random.randint(1, 300):03d}",
        "total_amount": total_amount
    })

    if random.random() < RETURNS_RATE:
        returns.append({
            "return_id": f"R{len(returns)+1:05d}",
            "transaction_id": txn_id,
            "return_reason": random.choice(return_reasons),
            "return_date": (txn_date + timedelta(days=random.randint(1, 20))).date()
        })

write_csv("datasets/customers.csv", customers, customers[0].keys())
write_csv("datasets/products.csv", products, products[0].keys())
write_csv("datasets/stores.csv", stores, stores[0].keys())
write_csv("datasets/inventory.csv", inventory, inventory[0].keys())
write_csv("datasets/promotions.csv", promotions, promotions[0].keys())
write_csv("datasets/sales_10000.csv", sales, sales[0].keys())
write_csv("datasets/returns.csv", returns, returns[0].keys())

print("Retail datasets generated successfully.")