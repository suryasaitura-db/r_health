#!/usr/bin/env python3
"""
Advanced Databricks Lakeview Dashboard Creation
Creates dashboards with queries and basic visualizations using Databricks API
"""
import requests
import os
import json
from pathlib import Path

# Databricks configuration
DATABRICKS_HOST = os.getenv("DATABRICKS_HOST", "https://fe-vm-hls-amer.cloud.databricks.com")
DATABRICKS_TOKEN = os.getenv("DATABRICKS_TOKEN")
WAREHOUSE_ID = "4b28691c780d9875"

if not DATABRICKS_TOKEN:
    print("ERROR: DATABRICKS_TOKEN environment variable not set")
    print("Please set: export DATABRICKS_TOKEN='your_token'")
    exit(1)

HEADERS = {
    "Authorization": f"Bearer {DATABRICKS_TOKEN}",
    "Content-Type": "application/json"
}

def create_sql_query(name, query, warehouse_id):
    """Create a SQL query using Databricks SQL API"""
    url = f"{DATABRICKS_HOST}/api/2.0/sql/queries"

    data = {
        "name": name,
        "query": query,
        "data_source_id": warehouse_id,
        "description": f"R_Health query: {name}"
    }

    try:
        response = requests.post(url, headers=HEADERS, json=data)
        response.raise_for_status()
        result = response.json()
        print(f"✓ Created query: {name} (ID: {result.get('id')})")
        return result.get('id')
    except Exception as e:
        print(f"✗ Error creating query {name}: {str(e)}")
        if hasattr(e, 'response') and e.response:
            print(f"  Response: {e.response.text}")
        return None


def create_lakeview_dashboard(name, parent_path="/Shared"):
    """Create a Lakeview dashboard using Databricks API"""
    url = f"{DATABRICKS_HOST}/api/2.0/lakeview/dashboards"

    data = {
        "display_name": name,
        "parent_path": parent_path,
        "warehouse_id": WAREHOUSE_ID
    }

    try:
        response = requests.post(url, headers=HEADERS, json=data)
        response.raise_for_status()
        result = response.json()
        dashboard_id = result.get('dashboard_id')
        print(f"✓ Created dashboard: {name} (ID: {dashboard_id})")
        print(f"  Path: {result.get('path')}")
        return dashboard_id, result.get('path')
    except Exception as e:
        print(f"✗ Error creating dashboard {name}: {str(e)}")
        if hasattr(e, 'response') and e.response:
            print(f"  Response: {e.response.text}")
        return None, None


def load_queries_from_file(filepath):
    """Load SQL queries from file"""
    try:
        with open(filepath, 'r') as f:
            content = f.read()

        # Simple parser to extract queries (separated by comments)
        queries = []
        current_query = []
        current_name = None

        for line in content.split('\n'):
            line = line.strip()

            # Skip empty lines
            if not line:
                continue

            # Check if this is a section header
            if line.startswith('--') and '###' in line:
                # Save previous query
                if current_query and current_name:
                    queries.append({
                        'name': current_name,
                        'query': '\n'.join(current_query).strip()
                    })
                    current_query = []

                # Extract query name
                current_name = line.replace('--', '').replace('#', '').strip()
            elif not line.startswith('--'):
                current_query.append(line)

        # Add last query
        if current_query and current_name:
            queries.append({
                'name': current_name,
                'query': '\n'.join(current_query).strip()
            })

        return queries
    except Exception as e:
        print(f"Error loading queries from {filepath}: {str(e)}")
        return []


def main():
    print("\n" + "="*80)
    print("R_HEALTH LAKEVIEW DASHBOARDS - ADVANCED CREATION")
    print("="*80)
    print(f"\nDatabricks Host: {DATABRICKS_HOST}")
    print(f"Warehouse ID: {WAREHOUSE_ID}")

    queries_dir = Path("dashboards/queries")

    dashboard_configs = [
        {
            "name": "R_Health - Capacity Management",
            "file": "01_capacity_management.sql"
        },
        {
            "name": "R_Health - Denials Management",
            "file": "02_denials_management.sql"
        },
        {
            "name": "R_Health - Clinical Trial Matching",
            "file": "03_clinical_trials.sql"
        },
        {
            "name": "R_Health - Timely Filing & Appeals",
            "file": "04_timely_filing.sql"
        },
        {
            "name": "R_Health - Documentation Management",
            "file": "05_documentation.sql"
        }
    ]

    created_dashboards = []

    for config in dashboard_configs:
        print(f"\n{'='*80}")
        print(f"Creating Dashboard: {config['name']}")
        print(f"{'='*80}")

        # Create Lakeview dashboard
        dashboard_id, dashboard_path = create_lakeview_dashboard(config['name'])

        if dashboard_id:
            created_dashboards.append({
                "name": config['name'],
                "id": dashboard_id,
                "path": dashboard_path,
                "url": f"{DATABRICKS_HOST}/sql/dashboardsv3/{dashboard_id}"
            })

            print(f"\n  Dashboard URL: {DATABRICKS_HOST}/sql/dashboardsv3/{dashboard_id}")

            # Load and create queries
            query_file = queries_dir / config['file']
            if query_file.exists():
                print(f"\n  Loading queries from: {config['file']}")
                queries = load_queries_from_file(query_file)
                print(f"  Found {len(queries)} queries")

                # Note: Creating SQL queries separately for reference
                # They won't be automatically added to the dashboard (requires UI or complex API)
                for q in queries[:3]:  # Create first 3 queries as examples
                    query_id = create_sql_query(
                        f"{config['name']} - {q['name'][:30]}",
                        q['query'],
                        WAREHOUSE_ID
                    )
            else:
                print(f"  Warning: Query file not found: {query_file}")

    # Summary
    print("\n" + "="*80)
    print("DASHBOARD CREATION COMPLETE")
    print("="*80)

    if created_dashboards:
        print(f"\nSuccessfully created {len(created_dashboards)} dashboards:\n")
        for dash in created_dashboards:
            print(f"  {dash['name']}")
            print(f"    ID: {dash['id']}")
            print(f"    Path: {dash['path']}")
            print(f"    URL: {dash['url']}")
            print()

        print("\n" + "="*80)
        print("NEXT STEPS")
        print("="*80)
        print("\nTo add visualizations to the dashboards:")
        print("1. Open each dashboard URL above in your browser")
        print("2. Click 'Edit' to enter edit mode")
        print("3. Add queries from dashboards/queries/ directory:")
        print("   - Click 'Add' → 'Visualization'")
        print("   - Paste SQL query from the .sql files")
        print("   - Configure chart type (bar, pie, table, counter)")
        print("   - Position and size the visualization")
        print("4. Click 'Publish' when done")
        print("\nAlternatively, use the Databricks UI to:")
        print("- Navigate to 'Dashboards' in the left sidebar")
        print("- Find 'R_Health' dashboards")
        print("- Edit and add the pre-built queries")
        print("="*80)

        # Save dashboard URLs to file
        with open('dashboard_urls.json', 'w') as f:
            json.dump(created_dashboards, f, indent=2)
        print("\nDashboard URLs saved to: dashboard_urls.json")

    return len(created_dashboards) > 0


if __name__ == "__main__":
    import sys
    success = main()
    sys.exit(0 if success else 1)
