# R_Health

Healthcare Analytics and Data Platform - Renown Health RFP Demo

This repository contains a complete healthcare analytics platform built with:
- Medallion Architecture (Bronze → Silver → Gold)
- FastAPI + React application framework
- Databricks Apps deployment
- AI/BI Dashboards
- 5 demo scenarios for Renown Health RFP

## Project Structure

```
r_health/
├── sql/
│   ├── 01_bronze/          # Bronze layer - Raw synthetic data
│   ├── 02_silver/          # Silver layer - Cleaned & enriched data
│   └── 03_gold/            # Gold layer - Business metrics & analytics
├── backend/                # FastAPI backend (future)
├── frontend/               # React frontend (future)
├── create_catalog_volume.py
├── create_volume.sql
├── execute_bronze_layer.py
└── README.md
```

## Unity Catalog Resources

### Created Resources
- **Bronze Schema**: `hls_amer_catalog.r_health_bronze`
- **Volume**: `hls_amer_catalog.r_health.r_health_volume`
- **Volume Path**: `/Volumes/hls_amer_catalog/r_health/r_health_volume`

### Bronze Layer Tables (✅ COMPLETED)
Executed successfully in 2.3 minutes - 50,000 patients with realistic synthetic data:

1. **patients** - Master Patient Index with KRAS/COPD status
2. **encounters** - ED visits, Observations, Inpatient admissions
3. **claims** - Insurance claims with payer mix (40% Medicare, 30% Medicaid, 30% Commercial)
4. **denials** - Denial tracking with appeal outcomes
5. **lab_results** - FEV1, NGS Panel, PD-L1 for clinical trial matching
6. **timely_filing** - 180-day filing deadline tracking
7. **documentation_requests** - Documentation request tracking

## Demo Scenarios (Option A - Synthetic Data)

1. **Capacity Management** - GMLOS optimization, 30-day readmission prevention
2. **Denials Management** - Pre-auth, denial review, appeal tracking
3. **Clinical Trial Matching** - KRAS G12C+ NSCLC, COPD trial eligibility
4. **Timely Filing & Appeals** - 180-day deadline monitoring
5. **Additional Documentation** - Doc request workflow tracking

## Usage

### Create Unity Catalog Volume
```bash
python3 create_catalog_volume.py
```

### Execute Bronze Layer
```bash
export DATABRICKS_TOKEN="your_token"
python3 execute_bronze_layer.py
```

## Implementation Status

- ✅ Phase 1: Bronze Layer (Synthetic Data) - COMPLETED
- ⏳ Phase 2: Silver Layer (Data Transformation)
- ⏳ Phase 3: Gold Layer (Business Metrics)
- ⏳ Phase 4-9: FastAPI + React Application
- ⏳ Phase 10-12: Deployment & Dashboards
