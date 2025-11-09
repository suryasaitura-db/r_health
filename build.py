#!/usr/bin/env python3
"""
Build script for R_Health Healthcare Analytics Platform
Prepares the application for Databricks Apps deployment
"""
import subprocess
import shutil
from pathlib import Path
import sys

def run_command(cmd, cwd=None, description=""):
    """Run a command and print output"""
    print(f"\n{'='*80}")
    print(f"{description}")
    print(f"{'='*80}")
    print(f"Running: {' '.join(cmd)}")

    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            check=True
        )
        print(result.stdout)
        if result.stderr:
            print("STDERR:", result.stderr)
        print(f"✓ {description} completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"✗ Error: {description} failed")
        print("STDOUT:", e.stdout)
        print("STDERR:", e.stderr)
        return False


def main():
    print("\n" + "="*80)
    print("R_HEALTH BUILD SCRIPT - DATABRICKS APPS DEPLOYMENT")
    print("="*80 + "\n")

    project_root = Path(__file__).parent
    frontend_dir = project_root / "frontend"
    backend_dir = project_root / "backend"

    # Step 1: Check if frontend directory exists
    if not frontend_dir.exists():
        print("✗ Frontend directory not found!")
        return False

    # Step 2: Install frontend dependencies if needed
    node_modules = frontend_dir / "node_modules"
    if not node_modules.exists():
        print("\nInstalling frontend dependencies...")
        if not run_command(
            ["npm", "install"],
            cwd=frontend_dir,
            description="Installing npm dependencies"
        ):
            return False
    else:
        print("✓ Frontend dependencies already installed")

    # Step 3: Build frontend
    if not run_command(
        ["npm", "run", "build"],
        cwd=frontend_dir,
        description="Building React frontend (Vite)"
    ):
        return False

    # Step 4: Verify frontend build output
    dist_dir = frontend_dir / "dist"
    if not dist_dir.exists():
        print("✗ Frontend build failed - dist directory not found")
        return False

    index_html = dist_dir / "index.html"
    if not index_html.exists():
        print("✗ Frontend build failed - index.html not found")
        return False

    print(f"\n✓ Frontend built successfully")
    print(f"  Output directory: {dist_dir}")
    print(f"  Files created:")
    for item in dist_dir.rglob("*"):
        if item.is_file():
            size = item.stat().st_size
            print(f"    - {item.relative_to(dist_dir)} ({size:,} bytes)")

    # Step 5: Verify backend files
    app_main = backend_dir / "app_main.py"
    if not app_main.exists():
        print("✗ Backend app_main.py not found")
        return False

    requirements = backend_dir / "requirements.txt"
    if not requirements.exists():
        print("✗ Backend requirements.txt not found")
        return False

    print("\n✓ Backend files verified")

    # Step 6: Check app.yaml exists
    app_yaml = project_root / "app.yaml"
    if not app_yaml.exists():
        print("✗ app.yaml not found in project root")
        return False

    print("✓ app.yaml found")

    # Final summary
    print("\n" + "="*80)
    print("BUILD COMPLETE - READY FOR DEPLOYMENT")
    print("="*80)
    print("\nDeployment files prepared:")
    print(f"  ✓ Frontend: {dist_dir}")
    print(f"  ✓ Backend: {backend_dir}")
    print(f"  ✓ Configuration: {app_yaml}")
    print("\nNext steps:")
    print("  1. Run: python deploy_to_databricks.py")
    print("  2. Or manually deploy with:")
    print("     databricks apps create r-health-analytics")
    print("     databricks apps deploy r-health-analytics --source-code-path .")
    print("="*80 + "\n")

    return True


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
