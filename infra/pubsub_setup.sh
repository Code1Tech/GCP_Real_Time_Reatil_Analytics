#!/bin/bash

gcloud pubsub topics create retail-sales-topic

gcloud pubsub topics create retail-inventory-topic

gcloud pubsub subscriptions create retail-sales-sub \
--topic=retail-sales-topic

gcloud pubsub subscriptions create retail-inventory-sub \
--topic=retail-inventory-topic