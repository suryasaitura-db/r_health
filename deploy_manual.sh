#!/usr/bin/env bash
# Manual deployment script for R_Health Databricks App
set -e

WORKSPACE_PATH="/Workspace/Users/suryasai.turaga@databricks.com/r-health-analytics"
APP_NAME="r-health-analytics"

echo "================================================================================  "
echo "R_HEALTH MANUAL DEPLOYMENT TO DATABRICKS APPS"
echo "================================================================================"

# Step 1: Build frontend
echo ""
echo "[1/4] Building frontend..."
cd frontend
npm run build
cd ..

# Step 2: Create workspace directory structure
echo ""
echo "[2/4] Creating workspace directory structure..."
databricks workspace mkdirs "$WORKSPACE_PATH"
databricks workspace mkdirs "$WORKSPACE_PATH/backend"
databricks workspace mkdirs "$WORKSPACE_PATH/frontend"
databricks workspace mkdirs "$WORKSPACE_PATH/frontend/dist"
databricks workspace mkdirs "$WORKSPACE_PATH/frontend/dist/assets"

# Step 3: Upload files using correct CLI syntax
echo ""
echo "[3/4] Uploading files..."

# Upload app.yaml
echo "Uploading app.yaml..."
databricks workspace import "$WORKSPACE_PATH/app.yaml" --file app.yaml --format AUTO --overwrite

# Upload backend files
echo "Uploading backend/app_simple.py..."
databricks workspace import "$WORKSPACE_PATH/backend/app_simple.py" --file backend/app_simple.py --language PYTHON --overwrite

echo "Uploading backend/requirements.txt..."
databricks workspace import "$WORKSPACE_PATH/backend/requirements.txt" --file backend/requirements.txt --format AUTO --overwrite

echo "Uploading backend/__init__.py..."
databricks workspace import "$WORKSPACE_PATH/backend/__init__.py" --file backend/__init__.py --language PYTHON --overwrite

# Upload frontend files
echo "Uploading frontend/dist/index.html..."
databricks workspace import "$WORKSPACE_PATH/frontend/dist/index.html" --file frontend/dist/index.html --format AUTO --overwrite

echo "Uploading frontend assets..."
for file in frontend/dist/assets/*; do
  filename=$(basename "$file")
  echo "  - $filename"
  databricks workspace import "$WORKSPACE_PATH/frontend/dist/assets/$filename" --file "$file" --format AUTO --overwrite
done

# Step 4: Deploy app
echo ""
echo "[4/4] Deploying app..."
databricks apps deploy "$APP_NAME" --source-code-path "$WORKSPACE_PATH" --mode SNAPSHOT

echo ""
echo "================================================================================"
echo "DEPLOYMENT COMPLETE"
echo "================================================================================"
echo ""
echo "Getting app URL..."
databricks apps get "$APP_NAME" --output json | grep -o '"url":"[^"]*"' | cut -d'"' -f4
