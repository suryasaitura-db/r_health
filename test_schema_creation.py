#!/usr/bin/env python3
"""
Test schema creation to understand error messages
"""
from databricks.sdk import WorkspaceClient

w = WorkspaceClient()
WAREHOUSE_ID = "4b28691c780d9875"

statement = "CREATE SCHEMA IF NOT EXISTS hls_amer_catalog.r_health_silver COMMENT 'Silver layer - Cleansed and enriched healthcare data'"

print("Testing schema creation...")
print(f"Statement: {statement}\n")

try:
    response = w.statement_execution.execute_statement(
        warehouse_id=WAREHOUSE_ID,
        statement=statement,
        wait_timeout="50s"
    )

    print(f"Response status: {response.status}")
    print(f"Response state: {response.status.state if response.status else 'None'}")

    if response.status and response.status.error:
        print(f"Error message: {response.status.error.message}")
        print(f"Error error_code: {response.status.error.error_code if hasattr(response.status.error, 'error_code') else 'N/A'}")

    if response.status and response.status.state == "SUCCEEDED":
        print("✓ Schema creation succeeded!")
    else:
        print("✗ Schema creation failed")

except Exception as e:
    print(f"Exception occurred: {e}")
    print(f"Exception type: {type(e)}")
