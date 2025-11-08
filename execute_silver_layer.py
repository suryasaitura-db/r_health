#!/usr/bin/env python3
"""
Execute Silver Layer SQL for R_Health Healthcare Analytics Platform
Transforms Bronze layer data with cleansing, enrichment, and business rules
"""
import requests
import os
import re
import time

# Configuration from environment variables
DB_HOST = os.getenv("DATABRICKS_HOST", "https://fe-vm-hls-amer.cloud.databricks.com")
DB_TOKEN = os.getenv("DATABRICKS_TOKEN")
WAREHOUSE_ID = os.getenv("DATABRICKS_WAREHOUSE_ID", "4b28691c780d9875")

if not DB_TOKEN:
    raise ValueError("DATABRICKS_TOKEN environment variable must be set")

def split_sql_statements(sql_content):
    """Split SQL content into individual statements"""
    # Remove comments
    sql_content = re.sub(r'--.*?$', '', sql_content, flags=re.MULTILINE)

    # Split by semicolon but preserve semicolons in strings
    statements = []
    current_statement = []
    in_string = False

    for line in sql_content.split('\n'):
        if not line.strip():
            continue

        # Check for string literals
        for char in line:
            if char == "'" and (not current_statement or current_statement[-1] != '\\'):
                in_string = not in_string

        current_statement.append(line)

        if line.rstrip().endswith(';') and not in_string:
            stmt = '\n'.join(current_statement).strip()
            if stmt and stmt != ';':
                statements.append(stmt.rstrip(';'))
            current_statement = []

    # Add any remaining statement
    if current_statement:
        stmt = '\n'.join(current_statement).strip()
        if stmt and stmt != ';':
            statements.append(stmt.rstrip(';'))

    return [s for s in statements if s.strip()]

def execute_sql_statement(statement, statement_num, total_statements):
    """Execute a single SQL statement via Databricks REST API"""
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

    # Extract statement preview (first 80 chars)
    preview = statement[:80].replace('\n', ' ').strip()
    if len(statement) > 80:
        preview += "..."

    print(f"[{statement_num}/{total_statements}] {preview}")

    try:
        response = requests.post(url, headers=headers, json=payload, timeout=150)

        if response.status_code == 200:
            result = response.json()
            status = result.get('status', {}).get('state', 'UNKNOWN')

            if status == 'SUCCEEDED':
                row_count = result.get('result', {}).get('row_count', 0)
                print(f"  ✓ Success (rows: {row_count})")
                return True, f"Success (rows: {row_count})"
            else:
                error_msg = result.get('status', {}).get('error', {}).get('message', 'Unknown error')
                print(f"  ✗ Status: {status}, Error: {error_msg[:200]}")
                return False, f"Status: {status}, Error: {error_msg[:200]}"
        else:
            error_text = response.text[:200]
            print(f"  ✗ HTTP {response.status_code}: {error_text}")
            return False, f"HTTP {response.status_code}: {error_text}"

    except Exception as e:
        error_msg = str(e)[:200]
        print(f"  ✗ Exception: {error_msg}")
        return False, f"Exception: {error_msg}"

def main():
    print("\n" + "="*80)
    print("R_HEALTH SILVER LAYER - DATA CLEANSING & ENRICHMENT")
    print("="*80)
    print(f"Host: {DB_HOST}")
    print(f"Warehouse ID: {WAREHOUSE_ID}")
    print("="*80 + "\n")

    # Read the Silver layer SQL file
    sql_file = "sql/02_silver/02_bronze_to_silver_transformations.sql"

    try:
        with open(sql_file, 'r') as f:
            sql_content = f.read()
    except FileNotFoundError:
        print(f"✗ Error: SQL file not found: {sql_file}")
        return

    # Split into individual statements
    statements = split_sql_statements(sql_content)
    total_statements = len(statements)

    print(f"Total statements to execute: {total_statements}\n")

    successful = 0
    failed = 0
    start_time = time.time()

    for i, statement in enumerate(statements, 1):
        success, message = execute_sql_statement(statement, i, total_statements)

        if success:
            successful += 1
        else:
            failed += 1

        # Small delay between statements
        time.sleep(0.5)

    elapsed_time = time.time() - start_time

    print("\n" + "="*80)
    print(f"Completed Silver Layer: {successful} succeeded, {failed} failed")
    print("="*80 + "\n")
    print(f"Layer completed in {elapsed_time:.1f} seconds ({elapsed_time/60:.1f} minutes)\n")

    if failed == 0:
        print("="*80)
        print("✓ SILVER LAYER CREATED SUCCESSFULLY!")
        print("="*80 + "\n")
        print("Created Schemas and Tables:\n")
        print("  📊 Silver Layer (hls_amer_catalog.r_health_silver)")
        print("     • patients (Enriched with trial eligibility & risk stratification)")
        print("     • encounters (GMLOS benchmarks & variance analysis)")
        print("     • claims (Financial metrics & denial priority)")
        print("     • denials (Appeal analytics & prevention categorization)")
        print("     • lab_results (Clinical trial matching & FEV1 stratification)")
        print("     • timely_filing (Deadline tracking & compliance status)")
        print("     • documentation_requests (Urgency tracking & complexity scoring)")
        print("="*80 + "\n")
    else:
        print(f"❌ Some steps failed ({failed} failures). Please review the errors above.\n")

if __name__ == "__main__":
    main()
