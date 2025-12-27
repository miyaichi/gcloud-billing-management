# GCloud Billing Management CLI

This tool helps you manage and analyze your Google Cloud billing data by setting up a dedicated project and providing a CLI to query monthly costs.

## 1. Initial Setup

This section guides you through setting up the necessary Google Cloud infrastructure using a `.env` file for configuration.

### Prerequisites

*   `gcloud` CLI is installed and authenticated (`gcloud auth login`).
*   You have a Google Cloud Billing Account and its ID. You can find your billing account ID by running:
    ```bash
    gcloud billing accounts list
    ```

### Step 1: Configure your Environment

1.  **Create a `.env` file:** Copy the example template to create your own local configuration file. This file is ignored by Git, so your secrets are safe.
    ```bash
    cp .env.example .env
    ```

2.  **Edit the `.env` file:** Open the newly created `.env` file in a text editor and replace the placeholder `BILLING_ACCOUNT_ID` with your actual billing account ID. You can also change `DATASET_LOCATION` if desired.

### Step 2: Run the Setup Script

The `setup_billing.sh` script reads your `.env` file to automate the creation of a new project and a BigQuery dataset.

1.  **Make the script executable:**
    ```bash
    chmod +x setup_billing.sh
    ```

2.  **Run the script:**
    ```bash
    ./setup_billing.sh
    ```
    The script will create a new project and then automatically update your `.env` file with the new `BILLING_PROJECT_ID`.

### Step 3: Configure Billing Export in Cloud Console

After the script finishes, you need to manually configure the billing export to send data to the newly created BigQuery dataset.

1.  Navigate to the [Billing Export](https://console.cloud.google.com/billing/export) page in the Google Cloud Console.
2.  Make sure you have selected the correct billing account.
3.  Click **"EDIT EXPORT"** or **"ADD EXPORT"**.
4.  Enable the **"Detailed usage cost"** export.
5.  From the "Project" dropdown, select the project created by the script (the ID is now in your `.env` file).
6.  From the "Dataset" dropdown, select the `billing_export` dataset.
7.  Click **"Save"**.

It may take a few hours for the billing data to start populating in your BigQuery dataset.

## 2. CLI Usage

The `billing_cli.py` script queries the billing data from BigQuery and displays the costs per project for the current or last month. It automatically uses the configuration from your `.env` file.

### Step 1: Install Dependencies

Install the required Python libraries using pip:
```bash
pip install -r requirements.txt
```

### Step 2: Run the CLI

**To get the current month's costs:**
```bash
python billing_cli.py --month current
```

**To get the last month's costs:**
```bash
python billing_cli.py --month last
```

**Example Output:**
```
--- Running query for last month (2025-11-01 to 2025-12-01) ---
Project ID                               | Total Cost      | Currency
-----------------------------------------------------------------
my-production-app-project                |         1234.56 | JPY
my-staging-environment                   |          789.01 | JPY
a-small-test-project                     |            0.12 | JPY
N/A (e.g., taxes, adjustments)           |           50.00 | JPY
```

**Note:** If the script shows no data, please wait a few hours and try again. It can take time for billing data to appear in BigQuery after the initial setup.
