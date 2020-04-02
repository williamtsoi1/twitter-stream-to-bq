#!/bin/sh

# Load variables from env file
set -o allexport
source ./.env
set +o allexport

# Destroy VM

# Destroy Dataflow job
gcloud dataflow jobs cancel $DATAFLOW_JOB_NAME --region=$LOCATION

# Destroy BigQuery dataset
bq rm -r -f -d $PROJECT:$BQ_DATASET_NAME

# Destroy pubsub description and topic
gcloud pubsub subscriptions delete $PUBSUB_SUBSCRIPTION
gcloud pubsub topics delete $PUBSUB_TOPIC

# Destroy service account
gcloud projects remove-iam-policy-binding $PROJECT \
  --member serviceAccount:$DATAFLOW_SA_NAME@$PROJECT.iam.gserviceaccount.com \
  --role roles/bigquery.dataEditor

gcloud projects remove-iam-policy-binding $PROJECT \
  --member serviceAccount:$DATAFLOW_SA_NAME@$PROJECT.iam.gserviceaccount.com \
  --role roles/pubsub.subscriber

gcloud projects remove-iam-policy-binding $PROJECT \
  --member serviceAccount:$DATAFLOW_SA_NAME@$PROJECT.iam.gserviceaccount.com \
  --role roles/dataflow.worker

gcloud -q iam service-accounts delete $DATAFLOW_SA_NAME@$PROJECT.iam.gserviceaccount.com