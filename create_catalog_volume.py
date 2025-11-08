#!/usr/bin/env python3
"""
Create R_Health Unity Catalog and Volume using Databricks REST API
"""
import requests
import json
import time
import os

# Configuration from environment variables
DB_HOST = os.getenv("DATABRICKS_HOST", "https://fe-vm-hls-amer.cloud.databricks.com")
DB_TOKEN = os.getenv("DATABRICKS_TOKEN")  # Set via: export DATABRICKS_TOKEN=dapi...
WAREHOUSE_ID = os.getenv("DATABRICKS_WAREHOUSE_ID", "4b28691c780d9875")

if not DB_TOKEN:
    raise ValueError("DATABRICKS_TOKEN environment variable must be set")

def execute_sql_statement(statement, statement_name):
    """Execute a single SQL statement via REST API"""
    url = f"{DB_HOST}/api/2.0/sql/statements/"
    headers = {
        "Authorization": f"Bearer {DB_TOKEN}",
        "Content-Type": "application/json"
    }

    payload = {
        "warehouse_id": WAREHOUSE_ID,
        "statement": statement,
        "wait_timeout": "50s"
    }

    try:
        response = requests.post(url, headers=headers, json=payload, timeout=60)

        if response.status_code == 200:
            result = response.json()
            status = result.get('status', {}).get('state', 'UNKNOWN')

            if status == 'SUCCEEDED':
                row_count = result.get('result', {}).get('row_count', 0)
                return True, f"Success (rows: {row_count})"
            else:
                error_msg = result.get('status', {}).get('error', {}).get('message', 'Unknown error')
                return False, f"Status: {status}, Error: {error_msg[:200]}"
        else:
            return False, f"HTTP {response.status_code}: {response.text[:200]}"

    except Exception as e:
        return False, f"Exception: {str(e)[:200]}"

def main():
    print("\n" + "="*80)
    print("R_HEALTH UNITY CATALOG AND VOLUME SETUP")
    print("="*80)
    print(f"Host: {DB_HOST}")
    print(f"Warehouse ID: {WAREHOUSE_ID}")
    print("="*80 + "\n")

    statements = [
        ("CREATE SCHEMA IF NOT EXISTS hls_amer_catalog.r_health COMMENT 'Healthcare Analytics Data Platform - Public datasets and data sources'",
         "Create r_health schema"),
        ("CREATE VOLUME IF NOT EXISTS hls_amer_catalog.r_health.r_health_volume COMMENT 'Volume for storing public healthcare datasets (CSV, JSON, Parquet, etc.)'",
         "Create r_health_volume"),
        ("DESCRIBE VOLUME hls_amer_catalog.r_health.r_health_volume",
         "Verify volume creation"),
        ("SELECT 'Volume Path: /Volumes/hls_amer_catalog/r_health/r_health_volume' AS info",
         "Display volume path")
    ]

    successful = 0
    failed = 0

    for i, (statement, description) in enumerate(statements, 1):
        print(f"[{i}/{len(statements)}] {description}")
        print(f"  SQL: {statement[:70]}...")

        success, message = execute_sql_statement(statement, description)

        if success:
            print(f"  ✓ {message}\n")
            successful += 1
        else:
            print(f"  ✗ {message}\n")
            failed += 1

        time.sleep(0.5)

    print("="*80)
    print(f"Completed: {successful} succeeded, {failed} failed")
    print("="*80 + "\n")

    if failed == 0:
        print("✓ R_Health Volume created successfully!")
        print("\nCreated Resources:")
        print("  • Schema: hls_amer_catalog.r_health")
        print("  • Volume: hls_amer_catalog.r_health.r_health_volume")
        print("\nVolume Path: /Volumes/hls_amer_catalog/r_health/r_health_volume")
        print("\nReady to download public datasets!")
    else:
        print("❌ Some steps failed. Please review the errors above.")

if __name__ == "__main__":
    main()
