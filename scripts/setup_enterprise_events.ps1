$PROJECT_ID = "gcp-project-usecase"
$TOPIC_ID = "retail-events-topic"
$SUBSCRIPTION_ID = "retail-events-sub"

gcloud config set project $PROJECT_ID

$topicExists = gcloud pubsub topics list `
    --filter="name:$TOPIC_ID" `
    --format="value(name)"

if (-not $topicExists) {
    Write-Host "Creating Pub/Sub topic..."
    gcloud pubsub topics create $TOPIC_ID
}
else {
    Write-Host "Topic already exists."
}

$subscriptionExists = gcloud pubsub subscriptions list `
    --filter="name:$SUBSCRIPTION_ID" `
    --format="value(name)"

if (-not $subscriptionExists) {
    Write-Host "Creating Pub/Sub subscription..."
    gcloud pubsub subscriptions create $SUBSCRIPTION_ID `
        --topic=$TOPIC_ID `
        --ack-deadline=60
}
else {
    Write-Host "Subscription already exists."
}

Write-Host ""
Write-Host "Enterprise retail Pub/Sub infrastructure is ready."