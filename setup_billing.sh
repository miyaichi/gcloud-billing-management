#!/bin/bash

# Exit on error
set -e

# --- Load Environment Variables ---
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
  # Using a combination of sed and export to handle comments and whitespace
  export $(grep -v '^#' "$ENV_FILE" | sed 's/ *= */=/g' | xargs)
else
  echo "❌ Error: .env file not found. Please create it by copying .env.example."
  exit 1
fi

# Check if required variable is set and not the default example value
if [ -z "$BILLING_ACCOUNT_ID" ] || [ "$BILLING_ACCOUNT_ID" == "012345-67890A-BCDEF1" ]; then
    echo "❌ Error: BILLING_ACCOUNT_ID is not set or is still the default example value in your .env file."
    echo "Please update .env with your actual Google Cloud Billing Account ID."
    exit 1
fi


# --- Configuration ---
# A new, unique project ID is generated for the billing administration project.
# Other variables like DATASET_NAME and DATASET_LOCATION are loaded from the .env file.
NEW_PROJECT_ID="billing-admin-$(date +%y%m%d%H%M)" 


# --- Script ---

echo "--- Creating new project: ${NEW_PROJECT_ID} ---"
gcloud projects create ${NEW_PROJECT_ID}

echo "--- Linking project to billing account: ${BILLING_ACCOUNT_ID} ---"
gcloud billing projects link ${NEW_PROJECT_ID} --billing-account ${BILLING_ACCOUNT_ID}

echo "--- Enabling BigQuery and Cloud Billing APIs for the new project ---"
gcloud services enable bigquery.googleapis.com --project ${NEW_PROJECT_ID}
gcloud services enable cloudbilling.googleapis.com --project ${NEW_PROJECT_ID} # Needed for billing export setup

echo "--- Creating BigQuery dataset: ${DATASET_NAME} in location: ${DATASET_LOCATION} ---"
bq --location=${DATASET_LOCATION} mk --dataset ${NEW_PROJECT_ID}:${DATASET_NAME}

# --- Update .env file ---
echo "--- Updating .env file with the new project ID ---"
# This command is macOS & Linux compatible. It looks for the BILLING_PROJECT_ID line and replaces it.
# If the line doesn't exist, it appends it to the file.
if grep -q "BILLING_PROJECT_ID=" "$ENV_FILE"; then
  # Using a temporary file to avoid issues with sed's in-place editing across different OS
  sed "s/BILLING_PROJECT_ID=.*/BILLING_PROJECT_ID=${NEW_PROJECT_ID}/" "${ENV_FILE}.tmp" && mv "${ENV_FILE}.tmp" "$ENV_FILE"
else
  echo -e "\nBILLING_PROJECT_ID=${NEW_PROJECT_ID}" >> "$ENV_FILE"
fi

echo "---"
echo "✅ Setup script finished successfully!"
echo "✅ BILLING_PROJECT_ID in .env file has been set to: ${NEW_PROJECT_ID}"
echo "---"
echo "Next steps:"
echo "1. Go to the Google Cloud Console."
echo "2. Navigate to 'Billing' -> 'Billing export'."
echo "3. Configure a new 'Detailed usage cost' export."
echo "4. Set the destination to the BigQuery dataset created by this script:"
echo "   - Project: ${NEW_PROJECT_ID}"
echo "   - Dataset: ${DATASET_NAME}"
echo "See README.md for more detailed instructions."
