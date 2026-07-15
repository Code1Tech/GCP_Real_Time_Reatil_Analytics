# GCP Real-Time Retail Analytics Platform

An enterprise retail data and AI platform built on Google Cloud.

## Architecture

The platform supports batch and real-time retail analytics:

```text
CSV / Enterprise Data Generator
              |
              v
        Cloud Storage
              |
              v
      BigQuery Bronze
              ^
              |
Retail Simulator -> Pub/Sub -> Dataflow
              |
              v
       Streaming Bronze
              |
              v
     Cloud Composer
              |
              v
       BigQuery Silver
              |
              v
        BigQuery Gold
          /       \
         v         v
 BigQuery ML     Looker

 Implemented Components
Enterprise retail data generator
Cloud Storage batch ingestion
Pub/Sub event streaming
Apache Beam / Dataflow event router
BigQuery Bronze, Silver and Gold layers
Customer 360
Store performance analytics
Inventory optimization
Returns analytics
Promotion effectiveness
Supply-chain KPIs
Cloud Composer orchestration
BigQuery ML demand forecasting
BigQuery ML customer churn analysis
Forecast and churn dashboard tables
Repository Structure
bronze/ — raw table DDL and ingestion SQL
silver/ — cleaned and conformed transformations
gold/ — business-ready analytical models
simulation/ — enterprise retail event simulator
dataflow/ — Pub/Sub-to-BigQuery streaming pipelines
composer/ — Cloud Composer / Airflow DAGs
ai/bqml/ — BigQuery ML training, evaluation and prediction SQL
verification/ — validation and reconciliation queries
docs/ — architecture, runbooks and demo documentation
Main GCP Services
Cloud Storage
Pub/Sub
Dataflow
BigQuery
BigQuery ML
Cloud Composer
Cloud Logging
Cloud Monitoring
Looker Studio
Data Layers
Bronze

Raw historical and streaming records.

Silver

Cleaned, deduplicated and enriched retail data.

Gold

Business-ready models for dashboards, KPIs and machine learning.

AI

Model training data, evaluations, forecasts and prediction outputs.

Current ML Models
Product demand forecasting using ARIMA_PLUS
Customer churn classification using logistic regression
Important

Do not commit service-account keys, credentials, .env files or generated production datasets.


## 7. Add a runbook for important commands

Create:

```powershell
ni docs\runbooks\powershell_commands.md -Force

# PowerShell Runbook

## Authenticate

```powershell
gcloud auth login
gcloud config set project gcp-project-usecase