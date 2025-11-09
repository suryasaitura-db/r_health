#!/usr/bin/env python3
"""Verify all Gold layer tables exist and have data"""
from databricks.sdk import WorkspaceClient

w = WorkspaceClient()
WAREHOUSE_ID = "4b28691c780d9875"

tables = [
    "capacity_management",
    "denials_management",
    "clinical_trial_matching",
    "timely_filing_appeals",
    "documentation_management"
]

print("\n" + "="*80)
print("VERIFYING GOLD LAYER TABLES")
print("="*80 + "\n")

for table in tables:
    query = f"SELECT COUNT(*) AS count FROM hls_amer_catalog.r_health_gold.{table}"
    try:
        response = w.statement_execution.execute_statement(
            warehouse_id=WAREHOUSE_ID,
            statement=query,
            wait_timeout="30s"
        )

        if response.result and response.result.data_array:
            count = response.result.data_array[0][0]
            print(f"✓ {table}: {count} records")
        else:
            print(f"✗ {table}: No data returned")
    except Exception as e:
        print(f"✗ {table}: {str(e)[:100]}")

print("\n" + "="*80 + "\n")
