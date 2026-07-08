# Looker Dashboard Mapping

## 1. Executive Retail Dashboard

Data source:

`gcp-project-usecase.retail_gold.executive_sales_kpi`

KPIs:
- Total Revenue
- Net Sales
- Gross Profit
- Gross Margin
- Total Orders
- Unique Customers
- Average Order Value
- Return Count

Charts:
- Revenue Trend by Date
- Revenue by Region
- Revenue by Store
- Revenue by Category
- Revenue by Brand
- Gross Margin by Category

Filters:
- Date
- Region
- Store
- Category
- Brand

---

## 2. Inventory Health Dashboard

Data source:

`gcp-project-usecase.retail_gold.inventory_health_kpi`

KPIs:
- Stock Out Count
- Understock Count
- Overstock Count
- Healthy Inventory Count
- Reorder Required Count

Charts:
- Inventory Status by Region
- Low Stock Products
- Overstock Products
- Warehouse Stock by Product
- Store Inventory Health

Filters:
- Region
- Store
- Category
- Brand
- Inventory Status

---

## 3. Customer Analytics Dashboard

Data source:

`gcp-project-usecase.retail_gold.customer_kpi`

KPIs:
- Total Customers
- Customer Lifetime Value
- Average Spend
- Total Orders
- High Churn Risk Customers

Charts:
- CLV by Loyalty Tier
- Churn Risk Segments
- Customers by State
- Average Spend by Gender
- Repeat Purchase Distribution

Filters:
- Loyalty Tier
- Gender
- State
- Churn Risk Segment

---

## 4. Product Performance Dashboard

Data source:

`gcp-project-usecase.retail_gold.product_performance_kpi`

KPIs:
- Total Units Sold
- Total Net Sales
- Total Profit
- Margin %
- Return Count

Charts:
- Top Products by Sales
- Top Products by Profit
- Product Velocity
- Category Contribution
- Brand Contribution
- Return Count by Product

Filters:
- Category
- Sub Category
- Brand
- Product Velocity

---

## 5. AI Insights Dashboard

Data sources:

`gcp-project-usecase.retail_gold.ai_demand_forecasting_features`

`gcp-project-usecase.retail_gold.ai_customer_churn_predictions`

`gcp-project-usecase.retail_gold.ai_product_recommendations`

KPIs:
- Forecasted Revenue
- Forecasted Quantity
- High Churn Risk Customers
- Top Recommended Products
- Basket Lift Opportunity

Charts:
- Demand Forecast Trend
- Churn Probability by Customer Segment
- Product Recommendation Network
- Forecast by Product
- Forecast by Region

Filters:
- Product
- Region
- Category
- Customer Segment