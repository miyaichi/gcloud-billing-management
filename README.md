# GCloud Billing Management CLI

This tool helps you manage and analyze your Google Cloud billing data.

## Features

*   Sets up a dedicated project and BigQuery dataset for billing data.
*   Provides a CLI to query monthly costs per project.

## 1. Initial Setup

This section guides you through setting up the necessary Google Cloud infrastructure.

### Prerequisites

*   `gcloud` CLI is installed and authenticated (`gcloud auth login`).
*   You have a Google Cloud Billing Account and its ID. You can find your billing account ID by running:
    ```bash
    gcloud billing accounts list
    ```

### Step 1: Run the Setup Script

The `setup_billing.sh` script automates the creation of a new project and a BigQuery dataset.

1.  **Edit the script:** Open `setup_billing.sh` and replace `YOUR_BILLING_ACCOUNT_ID` with your actual billing account ID. You can also customize the new project ID and dataset location if needed.

2.  **Make the script executable:**
    ```bash
    chmod +x setup_billing.sh
    ```

3.  **Run the script:**
    ```bash
    ./setup_billing.sh
    ```

### Step 2: Configure Billing Export in Cloud Console

After the script finishes, you need to manually configure the billing export to send data to the newly created BigQuery dataset.

1.  Navigate to the [Billing Export](https://console.cloud.google.com/billing/export) page in the Google Cloud Console.
2.  Make sure you have selected the correct billing account.
3.  Click **"EDIT EXPORT"** or **"ADD EXPORT"**.
4.  Enable the **"Detailed usage cost"** export.
5.  From the "Project" dropdown, select the project created by the script (e.g., `your-billing-admin-project-...`).
6.  From the "Dataset" dropdown, select the `billing_export` dataset.
7.  Click **"Save"**.

It may take a few hours for the billing data to start populating in your BigQuery dataset.

## 2. Usage

## 2. CLI Usage

The `billing_cli.py` script queries the billing data from BigQuery and displays the costs per project for the current or last month.

### Step 1: Install Dependencies

Install the required Python libraries using pip:

```bash
pip install -r requirements.txt
```

### Step 2: Run the CLI

To run the script, you need to provide the project ID created during the setup and the desired month (`current` or `last`).

Replace `[YOUR_BILLING_PROJECT_ID]` with the ID of the project created by the `setup_billing.sh` script.

**To get the current month's costs:**
```bash
python billing_cli.py --project [YOUR_BILLING_PROJECT_ID] --month current
```

**To get the last month's costs:**
```bash
python billing_cli.py --project [YOUR_BILLING_PROJECT_ID] --month last
```

**Example Output:**
```
--- Running query for last month (2023-11-01 to 2023-12-01) ---
Project ID                               | Total Cost      | Currency
-----------------------------------------------------------------
my-production-app-project                |         1234.56 | JPY
my-staging-environment                   |          789.01 | JPY
a-small-test-project                     |            0.12 | JPY
```

**Note:** It can take several hours for billing data to appear in BigQuery after the initial setup. If the script shows no data, please wait and try again later.
