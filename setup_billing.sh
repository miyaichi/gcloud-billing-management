#!/bin/bash

# Exit on error
set -e

# --- Configuration ---
# You can change these variables
NEW_PROJECT_ID="your-billing-admin-project-$(date +%Y%m%d)" # Creates a unique project ID
BILLING_ACCOUNT_ID="YOUR_BILLING_ACCOUNT_ID" # IMPORTANT: Replace with your billing account ID
DATASET_NAME="billing_export"
DATASET_LOCATION="asia-northeast1" # e.g., US, EU, asia-northeast1

# --- Script ---

echo "--- Creating new project: ${NEW_PROJECT_ID} ---"
gcloud projects create ${NEW_PROJECT_ID}

echo "--- Linking project to billing account: ${BILLING_ACCOUNT_ID} ---"
gcloud billing projects link ${NEW_PROJECT_ID} --billing-account ${BILLING_ACCOUNT_ID}

echo "--- Enabling BigQuery and Cloud Billing APIs for the new project ---"
gcloud services enable bigquery.googleapis.com --project ${NEW_PROJECT_ID}
gcloud services enable cloudbilling.googleapis.com --project ${NEW_PROJECT_ID} # Needed for billing export setup

echo "--- Creating BigQuery dataset: ${DATASET_NAME} ---"
bq --location=${DATASET_LOCATION} mk --dataset ${NEW_PROJECT_ID}:${DATASET_NAME}

echo "---"
echo "✅ Setup script finished successfully!"
echo "---"
echo "Next steps:"
echo "1. Go to the Google Cloud Console."
echo "2. Navigate to 'Billing' -> 'Billing export'."
echo "3. Configure a new 'Detailed usage cost' export."
echo "4. Set the destination to the BigQuery dataset created by this script:"
echo "   - Project: ${NEW_PROJECT_ID}"
echo "   - Dataset: ${DATASET_NAME}"
echo "See README.md for more detailed instructions."
