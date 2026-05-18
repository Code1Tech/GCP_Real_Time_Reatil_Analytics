#!/bin/bash

export PROJECT_ID="your-project-id"
export REGION="us-central1"
export BUCKET="retail-intelligence-$PROJECT_ID"

gcloud config set project $PROJECT_ID

gcloud services enable \
bigquery.googleapis.com \
pubsub.googleapis.com \
storage.googleapis.com \
composer.googleapis.com \
dataflow.googleapis.com \
dataform.googleapis.com \
logging.googleapis.com \
monitoring.googleapis.com

gsutil mb -l $REGION gs://$BUCKET