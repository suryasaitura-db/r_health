# R_Health Databricks Apps Deployment Guide

This guide covers deploying the R_Health Healthcare Analytics Platform to Databricks Apps.

## Prerequisites

1. **Databricks CLI** installed and configured
   ```bash
   pip install databricks-cli databricks-sdk
   ```

2. **Databricks Authentication** configured (~/.databrickscfg)
   ```ini
   [DEFAULT]
   host = https://your-workspace.cloud.databricks.com
   token = dapi...
   ```

3. **Node.js and npm** installed (for frontend build)
   ```bash
   node --version  # Should be v18+
   npm --version
   ```

## Deployment Steps

### Option 1: Automated Deployment (Recommended)

Run the automated deployment script:

```bash
python deploy_to_databricks.py
```

This script will:
1. Build the React frontend
2. Verify all required files
3. Upload to Databricks Workspace
4. Create/update the Databricks App
5. Deploy the application

### Option 2: Manual Deployment

#### Step 1: Build the Application

```bash
python build.py
```

This builds the React frontend and verifies all files are ready.

#### Step 2: Upload to Databricks Workspace

```bash
# Create workspace directory
databricks workspace mkdirs /Workspace/Users/your.email@databricks.com/r-health-analytics

# Upload files
databricks workspace import app.yaml /Workspace/Users/your.email@databricks.com/r-health-analytics/app.yaml --overwrite
databricks workspace import backend/app_main.py /Workspace/Users/your.email@databricks.com/r-health-analytics/backend/app_main.py --overwrite
databricks workspace import backend/requirements.txt /Workspace/Users/your.email@databricks.com/r-health-analytics/backend/requirements.txt --overwrite

# Upload frontend
databricks workspace import-dir frontend/dist /Workspace/Users/your.email@databricks.com/r-health-analytics/frontend/dist --overwrite
```

#### Step 3: Create Databricks App

```bash
databricks apps create r-health-analytics \
  --description "R_Health Healthcare Analytics Platform - Renown Health RFP Demo"
```

#### Step 4: Deploy the App

```bash
databricks apps deploy r-health-analytics \
  --source-code-path /Workspace/Users/your.email@databricks.com/r-health-analytics \
  --mode SNAPSHOT
```

## Verify Deployment

### Check App Status

```bash
databricks apps get r-health-analytics
```

### View App Logs

```bash
databricks apps logs r-health-analytics
```

### Access the Application

The app URL will be displayed in the deployment output or can be retrieved with:

```bash
databricks apps get r-health-analytics --output json | grep url
```

## Architecture

The deployed application consists of:

```
r-health-analytics/
├── app.yaml                 # Databricks Apps configuration
├── backend/
│   ├── app_main.py         # FastAPI application (serves API + frontend)
│   └── requirements.txt    # Python dependencies
└── frontend/
    └── dist/               # Built React application
        ├── index.html
        └── assets/
```

## Configuration

### Environment Variables

Set in `app.yaml`:

- `WAREHOUSE_ID`: Databricks SQL Warehouse ID (default: 4b28691c780d9875)
- `CATALOG_NAME`: Unity Catalog name (default: hls_amer_catalog)
- `ENVIRONMENT`: Deployment environment (default: production)

### Data Access

The application requires access to:

- **Catalog**: `hls_amer_catalog`
- **Schema**: `r_health_gold`
- **Tables**:
  - `capacity_management`
  - `denials_management`
  - `clinical_trial_matching`
  - `timely_filing_appeals`
  - `documentation_management`

## Troubleshooting

### App Won't Start

1. Check logs: `databricks apps logs r-health-analytics`
2. Verify warehouse ID is correct in app.yaml
3. Ensure Unity Catalog permissions are set

### Frontend Not Loading

1. Verify frontend was built: `ls frontend/dist/index.html`
2. Check that frontend/dist was uploaded to workspace
3. Verify app_main.py is serving static files

### API Errors

1. Check Unity Catalog access
2. Verify Gold layer tables exist
3. Test queries manually in SQL Editor

### Rebuild and Redeploy

```bash
# Clean previous build
rm -rf frontend/dist

# Rebuild and redeploy
python build.py
python deploy_to_databricks.py
```

## Local Testing

Before deploying, test locally:

```bash
# Terminal 1 - Backend
cd backend
python main.py

# Terminal 2 - Frontend
cd frontend
npm run dev

# Open http://localhost:3000
```

## Update Existing Deployment

To update an existing deployment:

```bash
# Option 1: Use deployment script (recommended)
python deploy_to_databricks.py

# Option 2: Manual redeploy
databricks apps deploy r-health-analytics \
  --source-code-path /Workspace/Users/your.email@databricks.com/r-health-analytics \
  --mode SNAPSHOT
```

## Delete App

To completely remove the app:

```bash
databricks apps delete r-health-analytics
```

## Support

For issues, check:
1. Databricks Apps documentation: https://docs.databricks.com/apps/
2. Application logs via Databricks CLI
3. Unity Catalog permissions

---

**Deployed Application Components**:
- ✅ React 18 Frontend (Material-UI)
- ✅ FastAPI Backend (14 REST endpoints)
- ✅ Databricks Unity Catalog Integration
- ✅ 5 Healthcare Analytics Scenarios
