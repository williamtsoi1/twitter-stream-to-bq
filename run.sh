#!/bin/sh

# Load variables from env file
set -o allexport
source ./.env
set +o allexport

# Set context for gcloud
gcloud config set project $PROJECT

# Enable GCP APIs
echo "Enabling GCP APIs"
gcloud services enable \
  dataflow.googleapis.com \
  bigquery.googleapis.com \
  bigquerystorage.googleapis.com \
  pubsub.googleapis.com
echo "GCP APIs enabled"

# Configure service account for Dataflow
echo "Creating Service Account for Dataflow"
gcloud iam service-accounts create $DATAFLOW_SA_NAME
gcloud projects add-iam-policy-binding $PROJECT \
  --member serviceAccount:$DATAFLOW_SA_NAME@$PROJECT.iam.gserviceaccount.com \
  --role roles/bigquery.dataEditor

gcloud projects add-iam-policy-binding $PROJECT \
  --member serviceAccount:$DATAFLOW_SA_NAME@$PROJECT.iam.gserviceaccount.com \
  --role roles/pubsub.subscriber

gcloud projects add-iam-policy-binding $PROJECT \
  --member serviceAccount:$DATAFLOW_SA_NAME@$PROJECT.iam.gserviceaccount.com \
  --role roles/dataflow.worker
echo "Service Account created"

# Create pubsub topic and subscription
echo "Creating PubSub topic and subscription..."
gcloud pubsub topics create $PUBSUB_TOPIC
gcloud pubsub subscriptions create $PUBSUB_SUBSCRIPTION --topic=$FQ_PUBSUB_TOPIC
echo "Pubsub topic and subscription created"

# Create BigQuery dataset and table using schema
echo "Creating BigQuery Dataset and Table"
bq --location=$BQ_LOCATION mk --dataset $PROJECT:$BQ_DATASET_NAME
bq mk --table $BQ_DATASET_NAME.$BQ_TABLE_NAME ./bigquery_schema.json
echo "BigQuery Dataset and Table created"

# Create Dataflow job
gcloud dataflow jobs run $DATAFLOW_JOB_NAME \
  --gcs-location=gs://dataflow-templates/latest/PubSub_Subscription_to_BigQuery \
  --region=$LOCATION \
  --service-account-email=$DATAFLOW_SA_NAME@$PROJECT.iam.gserviceaccount.com \
  --parameters \
    "inputSubscription=${FQ_PUBSUB_SUBSCRIPTION},\
outputTableSpec=${PROJECT}:${BQ_DATASET_NAME}.${BQ_TABLE_NAME}"

# Run twitter stream
