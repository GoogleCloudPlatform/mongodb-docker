#!/bin/bash
set -e
set -x

# Ensure all required env vars are supplied
for var in PROJECT BUCKET KEYFILE GCLOUD WORKINGDIR; do
  val=$(eval "echo \$$var")
  if [ -z "$val" ]; then
    echo "$var env variable is required"
    exit 1
  fi
done

cd "$WORKINGDIR"

if [[ "$GCLOUD" == *.tar.gz ]]; then
  # Extract the gcloud binary out of the tarball
  tar -xzf "$GCLOUD" -C .
  GCLOUD="google-cloud-sdk/bin/gcloud"
fi

# Setup auth and update gcloud
$GCLOUD auth activate-service-account --key-file=$KEYFILE
$GCLOUD config set project $PROJECT
$GCLOUD components install alpha -q
$GCLOUD components update -q

# Run the cloud build
$GCLOUD alpha container builds create . \
  --config=cloudbuild.yaml \
  --verbosity=info \
  --gcs-source-staging-dir="gs://$BUCKET/staging" \
  --gcs-log-dir="gs://$BUCKET/logs"
