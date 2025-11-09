#!/usr/bin/env python3
"""
Create Databricks AI/BI (Lakeview) Dashboards for R_Health Scenarios
Uses Databricks SDK to programmatically create dashboards
"""
from databricks.sdk import WorkspaceClient
from databricks.sdk.service.dashboards import Dashboard
import os
import json

# Initialize Databricks client
w = WorkspaceClient()
WAREHOUSE_ID = os.getenv("WAREHOUSE_ID", "4b28691c780d9875")

def create_capacity_management_dashboard():
    """Create Capacity Management Dashboard"""
    print("\n[1/5] Creating Capacity Management Dashboard...")

    dashboard_spec = {
        "display_name": "R_Health - Capacity Management",
        "warehouse_id": WAREHOUSE_ID,
        "serialized_dashboard": json.dumps({
            "pages": [{
                "name": "Capacity Management Overview",
                "displayName": "Capacity Management",
                "layout": [{
                    "widget": {
                        "name": "summary_metrics",
                        "textbox_spec": "# Capacity Management Dashboard\n\nOptimize hospital capacity and reduce length of stay"
                    },
                    "position": {"x": 0, "y": 0, "width": 6, "height": 2}
                }, {
                    "widget": {
                        "name": "cost_opportunity_by_drg",
                        "queries": [{
                            "name": "cost_opportunity",
                            "query": """
                                SELECT
                                    drg_code,
                                    primary_diagnosis_code,
                                    total_encounters,
                                    avg_los,
                                    gmlos_benchmark,
                                    estimated_cost_opportunity
                                FROM hls_amer_catalog.r_health_gold.capacity_management
                                ORDER BY estimated_cost_opportunity DESC
                                LIMIT 20
                            """
                        }]
                    },
                    "position": {"x": 0, "y": 2, "width": 12, "height": 8}
                }, {
                    "widget": {
                        "name": "summary_stats",
                        "queries": [{
                            "name": "summary",
                            "query": """
                                SELECT
                                    COUNT(*) as total_drgs,
                                    SUM(total_encounters) as total_encounters,
                                    SUM(total_bed_days) as total_bed_days,
                                    ROUND(AVG(avg_los), 2) as overall_avg_los,
                                    SUM(estimated_cost_opportunity) as total_cost_opportunity
                                FROM hls_amer_catalog.r_health_gold.capacity_management
                            """
                        }]
                    },
                    "position": {"x": 6, "y": 0, "width": 6, "height": 2}
                }]
            }]
        })
    }

    try:
        dashboard = w.lakeview.create(
            display_name=dashboard_spec["display_name"],
            warehouse_id=dashboard_spec["warehouse_id"]
        )
        print(f"✓ Created dashboard: {dashboard.display_name} (ID: {dashboard.dashboard_id})")
        return dashboard.dashboard_id
    except Exception as e:
        print(f"✗ Error creating Capacity Management dashboard: {str(e)}")
        return None


def create_denials_management_dashboard():
    """Create Denials Management Dashboard"""
    print("\n[2/5] Creating Denials Management Dashboard...")

    try:
        dashboard = w.lakeview.create(
            display_name="R_Health - Denials Management",
            warehouse_id=WAREHOUSE_ID
        )
        print(f"✓ Created dashboard: {dashboard.display_name} (ID: {dashboard.dashboard_id})")
        return dashboard.dashboard_id
    except Exception as e:
        print(f"✗ Error creating Denials Management dashboard: {str(e)}")
        return None


def create_clinical_trial_dashboard():
    """Create Clinical Trial Matching Dashboard"""
    print("\n[3/5] Creating Clinical Trial Matching Dashboard...")

    try:
        dashboard = w.lakeview.create(
            display_name="R_Health - Clinical Trial Matching",
            warehouse_id=WAREHOUSE_ID
        )
        print(f"✓ Created dashboard: {dashboard.display_name} (ID: {dashboard.dashboard_id})")
        return dashboard.dashboard_id
    except Exception as e:
        print(f"✗ Error creating Clinical Trial Matching dashboard: {str(e)}")
        return None


def create_timely_filing_dashboard():
    """Create Timely Filing & Appeals Dashboard"""
    print("\n[4/5] Creating Timely Filing & Appeals Dashboard...")

    try:
        dashboard = w.lakeview.create(
            display_name="R_Health - Timely Filing & Appeals",
            warehouse_id=WAREHOUSE_ID
        )
        print(f"✓ Created dashboard: {dashboard.display_name} (ID: {dashboard.dashboard_id})")
        return dashboard.dashboard_id
    except Exception as e:
        print(f"✗ Error creating Timely Filing dashboard: {str(e)}")
        return None


def create_documentation_dashboard():
    """Create Documentation Management Dashboard"""
    print("\n[5/5] Creating Documentation Management Dashboard...")

    try:
        dashboard = w.lakeview.create(
            display_name="R_Health - Documentation Management",
            warehouse_id=WAREHOUSE_ID
        )
        print(f"✓ Created dashboard: {dashboard.display_name} (ID: {dashboard.dashboard_id})")
        return dashboard.dashboard_id
    except Exception as e:
        print(f"✗ Error creating Documentation Management dashboard: {str(e)}")
        return None


def list_created_dashboards():
    """List all R_Health dashboards"""
    print("\n" + "="*80)
    print("CREATED DASHBOARDS")
    print("="*80)

    try:
        dashboards = w.lakeview.list()
        r_health_dashboards = [d for d in dashboards if d.display_name and d.display_name.startswith("R_Health")]

        if r_health_dashboards:
            print("\nR_Health Dashboards:")
            for dashboard in r_health_dashboards:
                print(f"  - {dashboard.display_name}")
                print(f"    ID: {dashboard.dashboard_id}")
                print(f"    Path: {dashboard.path}")
                print()
        else:
            print("\nNo R_Health dashboards found.")
    except Exception as e:
        print(f"Error listing dashboards: {str(e)}")


def main():
    print("\n" + "="*80)
    print("R_HEALTH LAKEVIEW DASHBOARDS CREATION")
    print("="*80)
    print(f"\nWarehouse ID: {WAREHOUSE_ID}")
    print("Creating 5 AI/BI dashboards for healthcare analytics scenarios...")

    dashboard_ids = []

    # Create all dashboards
    dashboard_ids.append(create_capacity_management_dashboard())
    dashboard_ids.append(create_denials_management_dashboard())
    dashboard_ids.append(create_clinical_trial_dashboard())
    dashboard_ids.append(create_timely_filing_dashboard())
    dashboard_ids.append(create_documentation_dashboard())

    # Summary
    successful = len([d for d in dashboard_ids if d is not None])

    print("\n" + "="*80)
    print("DASHBOARD CREATION COMPLETE")
    print("="*80)
    print(f"\nSuccessfully created: {successful}/5 dashboards")

    if successful > 0:
        list_created_dashboards()
        print("\n" + "="*80)
        print("NEXT STEPS")
        print("="*80)
        print("\n1. Open Databricks workspace")
        print("2. Navigate to 'Dashboards' in the left sidebar")
        print("3. Find the R_Health dashboards")
        print("4. Click on each dashboard to add visualizations:")
        print("   - Add SQL queries from dashboards/queries/ directory")
        print("   - Configure charts, tables, and metrics")
        print("   - Customize layouts and filters")
        print("5. Publish dashboards when ready")
        print("\nFor pre-built SQL queries, see:")
        print("  dashboards/queries/01_capacity_management.sql")
        print("  dashboards/queries/02_denials_management.sql")
        print("  dashboards/queries/03_clinical_trials.sql")
        print("  dashboards/queries/04_timely_filing.sql")
        print("  dashboards/queries/05_documentation.sql")
        print("="*80 + "\n")

    return successful == 5


if __name__ == "__main__":
    import sys
    success = main()
    sys.exit(0 if success else 1)
