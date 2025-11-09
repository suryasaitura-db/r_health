#!/bin/bash

# Deployment script for R_Health Dash Application
# This script uploads the Dash app files to Databricks workspace and deploys the app

set -e

echo "=========================================="
echo "R_Health Dash App Deployment"
echo "=========================================="

WORKSPACE_PATH="/Workspace/Users/suryasai.turaga@databricks.com/r-health-dash"
APP_NAME="r-health-dash"

echo "Step 1: Creating workspace directory..."
databricks workspace mkdirs "$WORKSPACE_PATH"

echo "Step 2: Uploading Dash app files..."
databricks workspace import "$WORKSPACE_PATH/app.yaml" --file dash_app/app.yaml --format AUTO --overwrite
databricks workspace import "$WORKSPACE_PATH/requirements.txt" --file dash_app/requirements.txt --format AUTO --overwrite
databricks workspace import "$WORKSPACE_PATH/__init__.py" --file dash_app/__init__.py --format AUTO --overwrite
databricks workspace import "$WORKSPACE_PATH/app.py" --file dash_app/app.py --format AUTO --overwrite

echo "Step 3: Creating Databricks App..."
databricks apps create "$APP_NAME" \
  --description "R_Health Healthcare Analytics Platform - Dash Framework with 5 Scenarios" \
  --output json 2>&1 || echo "App may already exist, continuing..."

echo "Step 4: Deploying app..."
databricks apps deploy "$APP_NAME" \
  --source-code-path "$WORKSPACE_PATH" \
  --mode SNAPSHOT \
  --output json

echo "Step 5: Starting app..."
sleep 5
databricks apps start "$APP_NAME" --output json 2>&1 || echo "App may already be starting..."

echo ""
echo "=========================================="
echo "Deployment initiated!"
echo "=========================================="
echo "App Name: $APP_NAME"
echo "Workspace Path: $WORKSPACE_PATH"
echo ""
echo "The app will be available at:"
echo "https://r-health-dash-1602460480284688.aws.databricksapps.com"
echo ""
echo "Check status with:"
echo "databricks apps get $APP_NAME --output json"
echo "=========================================="
