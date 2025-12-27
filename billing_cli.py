import argparse
import os
from datetime import datetime
from dateutil.relativedelta import relativedelta
from dotenv import load_dotenv
from google.cloud import bigquery
from google.api_core.exceptions import NotFound

def get_billing_table_name(client, project_id, dataset_name):
    """Finds the billing export table name in the dataset."""
    dataset_ref = client.dataset(dataset_name, project=project_id)
    try:
        tables = list(client.list_tables(dataset_ref))
    except NotFound:
        print(f"❌ Error: Dataset '{project_id}.{dataset_name}' not found.")
        print("Please make sure you have run the setup script and correctly configured billing export in the Cloud Console.")
        return None

    for table in tables:
        if table.table_id.startswith('gcp_billing_export_v1_'):
            return f"`{project_id}.{dataset_name}.{table.table_id}`"

    print(f"❌ Error: No billing export table (gcp_billing_export_v1_*) found in dataset '{project_id}.{dataset_name}'.")
    print("It may take a few hours for the table to be created after setting up the export.")
    return None

def get_monthly_costs(project_id, dataset_name, month):
    """Queries BigQuery to get costs for the specified month."""
    client = bigquery.Client()

    table_name = get_billing_table_name(client, project_id, dataset_name)
    if not table_name:
        return

    today = datetime.utcnow().date()
    if month == 'current':
        start_date = today.replace(day=1)
        end_date = today + relativedelta(months=1, day=1)
    elif month == 'last':
        last_month_end = today.replace(day=1)
        last_month_start = last_month_end - relativedelta(months=1)
        start_date = last_month_start
        end_date = last_month_end
    else:
        # This case should not be reached due to argparse choices
        print(f"❌ Error: Invalid month '{month}'. Use 'current' or 'last'.")
        return

    query = f"""
        SELECT
            project.id AS project_id,
            SUM(cost) AS total_cost,
            currency
        FROM
            {table_name}
        WHERE
            usage_start_time >= TIMESTAMP('{start_date.isoformat()}')
            AND usage_start_time < TIMESTAMP('{end_date.isoformat()}')
            AND cost > 0
        GROUP BY
            project_id, currency
        ORDER BY
            total_cost DESC
    """

    print(f"--- Running query for {month} month ({start_date.strftime('%Y-%m-%d')} to {end_date.strftime('%Y-%m-%d')}) ---")

    try:
        query_job = client.query(query)
        results = query_job.result() # Waits for the job to complete.

        if results.total_rows == 0:
            print("No billing data found for the specified period.")
            return

        print(f"{'Project ID':<40} | {'Total Cost':<15} | {'Currency'}")
        print("-" * 65)
        for row in results:
            # Handle cases where project ID might be null (e.g., for some service adjustments)
            project_display = row.project_id if row.project_id else "N/A (e.g., taxes, adjustments)"
            print(f"{project_display:<40} | {row.total_cost:15.2f} | {row.currency}")

    except Exception as e:
        print(f"❌ An error occurred while querying BigQuery: {e}")


def main():
    # Load environment variables from .env file
    load_dotenv()

    # Get configuration from environment variables
    project_id = os.getenv("BILLING_PROJECT_ID")
    dataset_name = os.getenv("DATASET_NAME")

    # Validate that required environment variables are set
    if not project_id:
        print("❌ Error: BILLING_PROJECT_ID is not set in your .env file.")
        print("   Please run the ./setup_billing.sh script first to set it automatically.")
        return
    if not dataset_name:
        print("❌ Error: DATASET_NAME is not set in your .env file.")
        return
    
    parser = argparse.ArgumentParser(
        description='Get monthly GCP billing costs per project. Configuration is loaded from the .env file.'
    )
    parser.add_argument(
        '--month',
        choices=['current', 'last'],
        required=True,
        help="The month to query: 'current' or 'last'."
    )
    args = parser.parse_args()

    get_monthly_costs(project_id, dataset_name, args.month)

if __name__ == '__main__':
    main()
