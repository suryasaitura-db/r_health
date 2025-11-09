#!/usr/bin/env python3
"""
Deployment script for R_Health Healthcare Analytics Platform
Deploys the application to Databricks Apps
"""
import subprocess
import json
import sys
from pathlib import Path

def run_command(cmd, description="", capture=True):
    """Run a command and return result"""
    print(f"\n{description}")
    print(f"Running: {' '.join(cmd)}")

    try:
        if capture:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            if result.stdout:
                print(result.stdout)
            if result.stderr:
                print("STDERR:", result.stderr)
            return result.stdout
        else:
            subprocess.run(cmd, check=True)
            return ""
    except subprocess.CalledProcessError as e:
        print(f"✗ Error: {description} failed")
        if capture and e.stdout:
            print("STDOUT:", e.stdout)
        if capture and e.stderr:
            print("STDERR:", e.stderr)
        return None


def main():
    print("\n" + "="*80)
    print("R_HEALTH DATABRICKS APPS DEPLOYMENT")
    print("="*80 + "\n")

    project_root = Path(__file__).parent
    app_name = "r-health-analytics"
    workspace_path = f"/Workspace/Users/suryasai.turaga@databricks.com/{app_name}"

    # Step 1: Build the application
    print("\n[1/5] Building application...")
    build_result = run_command(
        ["python", "build.py"],
        description="Building frontend and verifying backend"
    )
    if build_result is None:
        print("✗ Build failed. Please fix errors and try again.")
        return False

    # Step 2: Upload to Databricks workspace
    print("\n[2/5] Uploading to Databricks Workspace...")

    # Create workspace directory
    run_command(
        ["databricks", "workspace", "mkdirs", workspace_path],
        description=f"Creating workspace directory: {workspace_path}",
        capture=False
    )

    # Upload app files
    files_to_upload = [
        ("app.yaml", f"{workspace_path}/app.yaml"),
        ("backend/app_main.py", f"{workspace_path}/backend/app_main.py"),
        ("backend/requirements.txt", f"{workspace_path}/backend/requirements.txt"),
    ]

    for local_file, remote_path in files_to_upload:
        local_path = project_root / local_file
        if local_path.exists():
            run_command(
                ["databricks", "workspace", "import", str(local_path), remote_path, "--overwrite"],
                description=f"Uploading {local_file}",
                capture=False
            )
        else:
            print(f"⚠ Warning: {local_file} not found, skipping")

    # Upload frontend dist directory
    frontend_dist = project_root / "frontend" / "dist"
    if frontend_dist.exists():
        run_command(
            ["databricks", "workspace", "import-dir", str(frontend_dist), f"{workspace_path}/frontend/dist", "--overwrite"],
            description="Uploading frontend build",
            capture=False
        )
    else:
        print("✗ Frontend dist directory not found. Run build.py first.")
        return False

    # Step 3: Check if app exists
    print("\n[3/5] Checking if app exists...")
    app_list = run_command(
        ["databricks", "apps", "list", "--output", "json"],
        description="Listing existing apps"
    )

    app_exists = False
    if app_list:
        try:
            apps = json.loads(app_list)
            app_exists = any(app.get("name") == app_name for app in apps)
        except json.JSONDecodeError:
            print("Warning: Could not parse apps list")

    # Step 4: Create or update app
    if not app_exists:
        print(f"\n[4/5] Creating new app: {app_name}...")
        create_result = run_command(
            ["databricks", "apps", "create", app_name,
             "--description", "R_Health Healthcare Analytics Platform - Renown Health RFP Demo"],
            description=f"Creating Databricks App: {app_name}"
        )
        if create_result is None:
            print("✗ App creation failed")
            return False
    else:
        print(f"\n[4/5] App {app_name} already exists, will update...")

    # Step 5: Deploy app
    print(f"\n[5/5] Deploying app...")
    deploy_result = run_command(
        ["databricks", "apps", "deploy", app_name,
         "--source-code-path", workspace_path,
         "--mode", "SNAPSHOT"],
        description=f"Deploying {app_name} to Databricks Apps"
    )

    if deploy_result is None:
        print("✗ Deployment failed")
        return False

    # Get app status
    print("\n" + "="*80)
    print("DEPLOYMENT COMPLETE")
    print("="*80)

    status_result = run_command(
        ["databricks", "apps", "get", app_name, "--output", "json"],
        description="Getting app status"
    )

    if status_result:
        try:
            app_info = json.loads(status_result)
            print("\nApp Information:")
            print(f"  Name: {app_info.get('name', 'N/A')}")
            print(f"  Status: {app_info.get('state', 'N/A')}")
            if 'url' in app_info:
                print(f"  URL: {app_info['url']}")
                print(f"\n🎉 Application deployed successfully!")
                print(f"📊 Access your app at: {app_info['url']}")
            else:
                print("\n  ⚠ App deployed but URL not yet available")
                print("  Run: databricks apps get r-health-analytics")
                print("  to check the URL once the app is running")
        except json.JSONDecodeError:
            print("Warning: Could not parse app info")

    print("\n" + "="*80)
    print("\nNext Steps:")
    print("  1. Wait a few moments for the app to start")
    print("  2. Check app status: databricks apps get r-health-analytics")
    print("  3. View logs: databricks apps logs r-health-analytics")
    print("  4. Access the app URL displayed above")
    print("="*80 + "\n")

    return True


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
