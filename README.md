# R_Health Healthcare Analytics Platform

A comprehensive, production-ready healthcare analytics platform built for the Renown Health RFP demonstration. This enterprise-grade solution showcases advanced data engineering, modern web development, and AI-powered business intelligence capabilities using the Databricks platform.

## Table of Contents
- [Overview](#overview)
- [Technology Stack](#technology-stack)
- [Project Architecture](#project-architecture)
- [Project Structure](#project-structure)
- [Healthcare Scenarios](#healthcare-scenarios)
- [Quick Start Guide](#quick-start-guide)
- [Implementation Status](#implementation-status)
- [Data Pipeline](#data-pipeline)
- [API Reference](#api-reference)
- [Deployment](#deployment)
- [Documentation](#documentation)

## Overview

The R_Health Healthcare Analytics Platform is a complete end-to-end solution that demonstrates healthcare data engineering and analytics capabilities. The platform processes 15,000 synthetic patients with 50,000+ encounters across five critical healthcare scenarios, delivering actionable insights through multiple interfaces.

### Key Features
- **Medallion Architecture**: Bronze → Silver → Gold data processing pipeline
- **RESTful API**: 14 FastAPI endpoints for programmatic access
- **Modern Web Interface**: React 18 with Material-UI for intuitive data visualization
- **AI/BI Dashboards**: 40+ SQL queries powering Databricks Lakeview dashboards
- **Enterprise Deployment**: Databricks Apps for scalable, secure hosting
- **Comprehensive Analytics**: 5 healthcare scenarios covering capacity, denials, trials, compliance, and documentation

### Business Value
- **Cost Optimization**: Identify $2.5M+ in capacity management opportunities
- **Revenue Recovery**: Track $1.8M in denied claims and appeal success rates
- **Clinical Innovation**: Match 847 patients to KRAS, COPD, and PD-L1 clinical trials
- **Compliance Management**: Monitor 180-day filing deadlines for $12M in claims
- **Operational Excellence**: Track 2,400+ documentation requests with SLA compliance

## Technology Stack

### Data Platform
- **Databricks Unity Catalog**: Data governance and management
- **SQL Serverless Warehouse**: High-performance query execution (ID: `4b28691c780d9875`)
- **Delta Lake**: ACID transactions and time travel capabilities
- **Medallion Architecture**: Bronze, Silver, Gold data layers

### Backend Services
- **FastAPI 0.104+**: Modern Python web framework
- **Databricks SDK**: Native platform integration
- **Python 3.9+**: Core programming language
- **Uvicorn**: ASGI server for production deployment

### Frontend Application
- **React 18.2**: Modern component-based UI
- **Material-UI 5.15**: Enterprise design system
- **Recharts 2.10**: Advanced data visualization
- **React Router 6.21**: Client-side routing
- **Vite 5.0**: Fast build tooling and HMR
- **Axios**: HTTP client for API communication

### Business Intelligence
- **Databricks AI/BI Dashboards**: Lakeview dashboard platform
- **40 SQL Queries**: Comprehensive analytics coverage (1,183 lines)
- **Real-time Insights**: Direct connection to Gold layer tables

### Development & Deployment
- **Databricks Apps**: Production hosting platform
- **Git**: Version control and collaboration
- **Python Scripts**: Automated deployment and build processes

## Project Architecture

### Medallion Data Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                    BRONZE LAYER                              │
│              (hls_amer_catalog.r_health_bronze)              │
├──────────────────────────────────────────────────────────────┤
│  Raw Synthetic Healthcare Data - 15,000 Patients             │
│  ├── patients (15K records)                                  │
│  ├── encounters (50K+ records)                               │
│  ├── claims (48K records)                                    │
│  ├── denials (12K records)                                   │
│  ├── lab_results (45K records)                               │
│  ├── timely_filing (48K records)                             │
│  └── documentation_requests (2.4K records)                   │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    SILVER LAYER                              │
│              (hls_amer_catalog.r_health_silver)              │
├──────────────────────────────────────────────────────────────┤
│  Cleansed & Enriched - Business Logic Applied                │
│  ├── patients_clean (demographics + biomarkers)              │
│  ├── encounters_clean (visit details + LOS)                  │
│  ├── claims_clean (billing + payer info)                     │
│  ├── denials_clean (denial tracking + appeals)               │
│  ├── lab_results_clean (FEV1, NGS, PD-L1)                    │
│  ├── timely_filing_clean (compliance tracking)               │
│  └── documentation_requests_clean (workflow data)            │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                     GOLD LAYER                               │
│               (hls_amer_catalog.r_health_gold)               │
├──────────────────────────────────────────────────────────────┤
│  Analytics-Ready Business Datasets                           │
│  ├── capacity_management (DRG optimization)                  │
│  ├── denials_management (appeal tracking)                    │
│  ├── clinical_trial_matching (eligibility)                   │
│  ├── timely_filing_appeals (compliance)                      │
│  └── documentation_management (SLA tracking)                 │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  CONSUMPTION LAYER                           │
├──────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   FastAPI    │  │  React App   │  │   Lakeview   │      │
│  │  (14 APIs)   │  │  (5 Pages)   │  │(40 Queries)  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└──────────────────────────────────────────────────────────────┘
```

### Application Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Databricks Apps                           │
│                  (Production Hosting)                         │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────────────────────────────────────────┐     │
│  │  FastAPI Backend (app_main.py)                     │     │
│  │  ├── REST API Endpoints                            │     │
│  │  ├── SQL Query Execution                           │     │
│  │  ├── Static File Serving (React build)             │     │
│  │  └── CORS Configuration                            │     │
│  └────────────────────────────────────────────────────┘     │
│                         ↕                                     │
│  ┌────────────────────────────────────────────────────┐     │
│  │  React Frontend (Vite Build)                       │     │
│  │  ├── 5 Scenario Dashboards                         │     │
│  │  ├── Material-UI Components                        │     │
│  │  ├── Recharts Visualizations                       │     │
│  │  └── Responsive Design                             │     │
│  └────────────────────────────────────────────────────┘     │
│                                                               │
└──────────────────────────────────────────────────────────────┘
                         ↕
┌──────────────────────────────────────────────────────────────┐
│         Databricks SQL Serverless Warehouse                  │
│              (4b28691c780d9875)                              │
└──────────────────────────────────────────────────────────────┘
                         ↕
┌──────────────────────────────────────────────────────────────┐
│              Unity Catalog (hls_amer_catalog)                │
│         Bronze → Silver → Gold Tables                        │
└──────────────────────────────────────────────────────────────┘
```

## Project Structure

```
r_health/
│
├── sql/                                    # SQL Data Pipeline
│   ├── 01_bronze/
│   │   └── 01_generate_synthetic_healthcare_data.sql
│   ├── 02_silver/
│   │   └── 02_bronze_to_silver_transformations.sql
│   └── 03_gold/
│       └── 03_silver_to_gold_business_datasets.sql
│
├── backend/                                # FastAPI Backend
│   ├── main.py                            # Local development server
│   ├── app_main.py                        # Databricks Apps server
│   └── test_api.py                        # API testing utilities
│
├── frontend/                               # React Frontend
│   ├── src/
│   │   ├── main.jsx                       # Application entry
│   │   ├── App.jsx                        # Main app component (248 lines)
│   │   ├── pages/
│   │   │   ├── Home.jsx                   # Landing page (150 lines)
│   │   │   ├── CapacityManagement.jsx     # Scenario 1 (286 lines)
│   │   │   ├── DenialsManagement.jsx      # Scenario 2 (293 lines)
│   │   │   ├── ClinicalTrials.jsx         # Scenario 3 (321 lines)
│   │   │   ├── TimelyFiling.jsx           # Scenario 4 (304 lines)
│   │   │   └── DocumentationManagement.jsx # Scenario 5 (334 lines)
│   │   ├── components/                    # Reusable UI components
│   │   ├── services/                      # API integration
│   │   └── utils/                         # Utility functions
│   ├── package.json                       # Dependencies
│   ├── vite.config.js                     # Build configuration
│   └── index.html                         # HTML template
│
├── dashboards/                             # AI/BI Lakeview
│   └── queries/
│       ├── 01_capacity_management.sql     # 194 lines, 8 queries
│       ├── 02_denials_management.sql      # 206 lines, 8 queries
│       ├── 03_clinical_trials.sql         # 244 lines, 8 queries
│       ├── 04_timely_filing.sql           # 255 lines, 8 queries
│       └── 05_documentation.sql           # 284 lines, 8 queries
│
├── deployment/                             # Deployment Scripts
│   ├── build.py                           # Build frontend assets
│   ├── deploy_to_databricks.py            # Deploy to Databricks Apps
│   └── app.yaml                           # Databricks Apps config
│
├── data_pipeline/                          # Pipeline Execution
│   ├── execute_bronze_layer.py            # Bronze layer loader
│   ├── execute_silver_layer_sdk.py        # Silver transformation
│   ├── execute_gold_layer_sdk.py          # Gold aggregation
│   └── create_lakeview_dashboards.py      # Dashboard provisioning
│
├── README.md                               # This file
├── DEMO_GUIDE.md                          # Demo walkthrough
├── PROJECT_SUMMARY.md                     # Executive summary
├── DEPLOYMENT.md                          # Deployment instructions
└── .gitignore                             # Git ignore rules
```

## Healthcare Scenarios

### 1. Capacity Management
**Objective**: Optimize hospital capacity and reduce length of stay (LOS)

**Key Metrics**:
- 157 DRG codes analyzed
- 48,362 encounters tracked
- 15,000 unique patients
- $2.5M+ cost opportunity identified
- Average LOS: 4.8 days vs GMLOS: 3.2 days

**Features**:
- DRG-level LOS variance analysis
- GMLOS benchmark comparison
- Excess bed days calculation
- Priority scoring (Critical/High/Low)
- Cost opportunity estimation

**Business Impact**: Identify which DRGs have the highest LOS variance to prioritize clinical pathway optimization and reduce excess bed days.

---

### 2. Denials Management
**Objective**: Track claim denials, manage appeals, and recover revenue

**Key Metrics**:
- 11,628 denied claims
- 5,814 appeals submitted
- $1.8M total denied amount
- $894K recovered through appeals
- 77.3% average appeal win rate

**Features**:
- Denial categorization (Authorization, Medical Necessity, Coding, etc.)
- Payer-specific denial patterns
- Appeal success tracking
- Financial recovery analysis
- Priority scoring for high-value appeals

**Business Impact**: Maximize revenue recovery by focusing appeal efforts on high-value denials with strong win probabilities.

---

### 3. Clinical Trial Matching
**Objective**: Match eligible patients to clinical trials for precision medicine

**Key Metrics**:
- 847 trial-eligible patients identified
- 283 KRAS G12C+ NSCLC candidates
- 292 COPD trial candidates (FEV1 30-60%)
- 284 PD-L1 >50% candidates
- 12 patients eligible for multiple trials

**Trial Criteria**:
- **KRAS Trial**: NSCLC + KRAS G12C mutation + Age 18-85
- **COPD Trial**: COPD diagnosis + FEV1 30-60% + Age 40-80
- **PD-L1 Trial**: NSCLC + PD-L1 >50% + No prior immunotherapy

**Business Impact**: Accelerate trial enrollment and advance precision medicine initiatives by identifying eligible patient populations.

---

### 4. Timely Filing & Appeals
**Objective**: Monitor 180-day filing deadlines and prevent revenue loss

**Key Metrics**:
- 48,362 claims monitored
- 1,694 at-risk claims (within 30 days of deadline)
- $12.1M in billed amounts tracked
- $1.9M at-risk amount
- Average 98 days to deadline

**Urgency Levels**:
- **Critical**: <15 days to deadline (urgency score 90+)
- **High**: 15-30 days to deadline (urgency score 70-89)
- **Medium**: 30-60 days to deadline (urgency score 40-69)
- **Low**: >60 days to deadline (urgency score <40)

**Business Impact**: Prevent revenue loss from timely filing denials through proactive deadline monitoring and prioritization.

---

### 5. Documentation Management
**Objective**: Track documentation requests and maintain SLA compliance

**Key Metrics**:
- 2,400 documentation requests
- 1,680 completed (70% completion rate)
- 8.4 days average turnaround time
- $34.2M in associated claim value
- 72.3% SLA compliance score

**Request Types**:
- Medical Records Review
- Clinical Documentation Improvement (CDI)
- Authorization Documentation
- Appeal Support Documentation

**Business Impact**: Improve claim adjudication success rates and reduce denials through timely, high-quality documentation delivery.

## Quick Start Guide

### Prerequisites
- Python 3.9+
- Node.js 18+
- Databricks workspace access
- Unity Catalog enabled
- SQL Serverless Warehouse

### Installation

#### 1. Clone Repository
```bash
git clone <repository-url>
cd r_health
```

#### 2. Set Up Data Pipeline

**Execute Bronze Layer** (Raw synthetic data):
```bash
export DATABRICKS_TOKEN="your_token_here"
python3 execute_bronze_layer.py
```
Expected output: 15,000 patients, 50,000+ encounters loaded in ~2.3 minutes

**Execute Silver Layer** (Data cleansing):
```bash
python3 execute_silver_layer_sdk.py
```
Expected output: 7 cleansed tables with business logic applied

**Execute Gold Layer** (Analytics datasets):
```bash
python3 execute_gold_layer_sdk.py
```
Expected output: 5 analytical tables ready for consumption

#### 3. Run Backend API (Local Development)

```bash
cd backend
pip install fastapi uvicorn databricks-sdk

# Set environment variables
export DATABRICKS_TOKEN="your_token_here"
export WAREHOUSE_ID="4b28691c780d9875"

# Start server
python main.py
```

API available at: `http://localhost:8000`
API documentation: `http://localhost:8000/docs`

#### 4. Run Frontend Application

```bash
cd frontend
npm install
npm run dev
```

Application available at: `http://localhost:5173`

#### 5. Deploy to Databricks Apps

```bash
# Build frontend
python3 build.py

# Deploy to Databricks
python3 deploy_to_databricks.py
```

Access deployed app in Databricks workspace under "Apps"

### Quick API Test

```bash
# Health check
curl http://localhost:8000/health

# Get capacity management data
curl http://localhost:8000/api/capacity-management?limit=10

# Get denials summary
curl http://localhost:8000/api/denials-management/summary

# Get clinical trial eligible patients
curl http://localhost:8000/api/clinical-trial-matching?eligible_only=true
```

## Implementation Status

All 11 phases completed - Production ready!

### Phase 1: Bronze Layer - COMPLETED
- 7 bronze tables created
- 15,000 synthetic patients
- 50,000+ encounters
- Realistic healthcare data with KRAS, COPD, FEV1, PD-L1 biomarkers
- Execution time: 2.3 minutes

### Phase 2: Silver Layer - COMPLETED
- 7 silver tables with data cleansing
- Business logic applied
- Data quality validation
- Enrichment with calculated fields

### Phase 3: Gold Layer - COMPLETED
- 5 analytical datasets
- Complex aggregations and metrics
- Business KPIs calculated
- Optimization scoring algorithms

### Phase 4: FastAPI Backend - COMPLETED
- 14 REST API endpoints
- Databricks SQL integration
- CORS configuration
- Error handling and validation
- API documentation (Swagger/OpenAPI)

### Phases 5-9: React Frontend - COMPLETED
- 5 complete scenario dashboards (1,949 lines)
- Material-UI component library
- Recharts data visualizations
- Responsive design
- API integration with loading states
- Error handling and user feedback

### Phase 10: Databricks Apps Deployment - COMPLETED
- Build automation (build.py)
- Deployment scripts (deploy_to_databricks.py)
- App configuration (app.yaml)
- Static file serving
- Production-ready hosting

### Phase 11: AI/BI Lakeview Dashboards - COMPLETED
- 40 SQL queries (1,183 lines)
- 5 dashboard configurations
- Real-time data visualization
- Interactive filters and drill-downs

## Data Pipeline

### Bronze Layer Tables
| Table | Records | Description |
|-------|---------|-------------|
| patients | 15,000 | Demographics, KRAS status, COPD diagnosis |
| encounters | 50,362 | ED, Observation, Inpatient visits |
| claims | 48,362 | Insurance claims with payer mix |
| denials | 11,628 | Denial tracking with appeal outcomes |
| lab_results | 45,000 | FEV1, NGS Panel, PD-L1 results |
| timely_filing | 48,362 | 180-day deadline tracking |
| documentation_requests | 2,400 | Doc request workflow |

### Silver Layer Tables
- **patients_clean**: Demographics + biomarker status
- **encounters_clean**: Visit details + calculated LOS
- **claims_clean**: Billing data + payer categorization
- **denials_clean**: Denial tracking + appeal outcomes
- **lab_results_clean**: Lab values + clinical interpretation
- **timely_filing_clean**: Deadline tracking + urgency scoring
- **documentation_requests_clean**: Request workflow + SLA metrics

### Gold Layer Tables
- **capacity_management**: DRG-level LOS optimization (157 rows)
- **denials_management**: Payer/denial category analytics (468 rows)
- **clinical_trial_matching**: Patient eligibility scoring (847 rows)
- **timely_filing_appeals**: Compliance deadline monitoring (48,362 rows)
- **documentation_management**: Request tracking & SLA (120 rows)

## API Reference

### Scenario Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | API information and endpoint list |
| `/health` | GET | Health check |
| `/api/capacity-management` | GET | Capacity analytics with filters |
| `/api/capacity-management/summary` | GET | Capacity summary statistics |
| `/api/denials-management` | GET | Denials analytics with filters |
| `/api/denials-management/summary` | GET | Denials summary statistics |
| `/api/clinical-trial-matching` | GET | Trial eligibility with filters |
| `/api/clinical-trial-matching/summary` | GET | Trial matching summary |
| `/api/timely-filing-appeals` | GET | Filing compliance with filters |
| `/api/timely-filing-appeals/summary` | GET | Filing summary statistics |
| `/api/documentation-management` | GET | Documentation tracking with filters |
| `/api/documentation-management/summary` | GET | Documentation summary |
| `/api/payers` | GET | List of all payers |
| `/api/drg-codes` | GET | List of all DRG codes |

### Example API Calls

```bash
# Capacity Management - Critical priority only
curl "http://localhost:8000/api/capacity-management?priority=Critical&limit=20"

# Denials Management - Medicare denials
curl "http://localhost:8000/api/denials-management?payer=Medicare&limit=50"

# Clinical Trials - KRAS eligible patients
curl "http://localhost:8000/api/clinical-trial-matching?trial_type=KRAS&eligible_only=true"

# Timely Filing - Critical urgency claims
curl "http://localhost:8000/api/timely-filing-appeals?urgency=Critical"

# Documentation - High urgency requests
curl "http://localhost:8000/api/documentation-management?urgency=High"
```

## Deployment

### Live Deployments

#### Option-C Dash Application (NEW - Purple/Teal Theme)
**Status:** RUNNING
**URL:** https://r-health-dash-option-c-1602460480284688.aws.databricksapps.com
**Features:** Modern purple/teal gradient theme with smooth CSS animations

#### Original Dash Application (Blue Theme)
**Status:** RUNNING
**URL:** https://r-health-dash-1602460480284688.aws.databricksapps.com
**Features:** Classic blue theme healthcare analytics

#### AI/BI Lakeview Dashboards (5 Dashboards)
All dashboards available at: https://fe-vm-hls-amer.cloud.databricks.com/sql/dashboards

1. **Capacity Management**: https://fe-vm-hls-amer.cloud.databricks.com/sql/dashboardsv3/01f0bd1bfac412338ed9128ce622faf7
2. **Denials Management**: https://fe-vm-hls-amer.cloud.databricks.com/sql/dashboardsv3/01f0bd1bfb0a169abb63051cf302d657
3. **Clinical Trial Matching**: https://fe-vm-hls-amer.cloud.databricks.com/sql/dashboardsv3/01f0bd1bfb561e3db274a29d97e67ccb
4. **Timely Filing & Appeals**: https://fe-vm-hls-amer.cloud.databricks.com/sql/dashboardsv3/01f0bd1bfb98119cb47f6cf14fe102d4
5. **Documentation Management**: https://fe-vm-hls-amer.cloud.databricks.com/sql/dashboardsv3/01f0bd1bfbe61fec87bd0d61c98f4194

### Deployment Comparison: Original vs Option-C

| Feature | Original Dash App | Option-C Dash App (NEW) |
|---------|------------------|-------------------------|
| **Theme** | Blue (#1976D2) | Purple/Teal Gradient (#6B46C1 + #14B8A6) |
| **Animations** | Basic | Advanced CSS (fade-in, slide-in, hover) |
| **Navigation** | Static links | Animated underlines on hover |
| **Cards** | Standard shadows | Hover elevation & transformations |
| **Color Scheme** | Blue monochrome | Purple-to-Teal gradient |
| **Effects** | Standard | Pulse, scale, smooth transitions |
| **Deployment Name** | r-health-dash | r-health-dash-option-c |
| **URL** | ...r-health-dash... | ...r-health-dash-option-c... |
| **Status** | Running | Running |

### Local Development
```bash
# Backend
cd backend && python main.py

# Frontend
cd frontend && npm run dev
```

### Production Deployment (Databricks Apps)

**Original Dash App:**
```bash
cd dash_app
bash ../deploy_dash_app.sh
```

**Option-C Dash App (Purple/Teal Theme):**
```bash
cd r_health_dash_option_c
bash ../deploy_option_c.sh
```

**React + FastAPI App:**
```bash
# Build frontend
python3 build.py

# Deploy application
python3 deploy_to_databricks.py
```

### Environment Variables
```bash
# Required for local development
export DATABRICKS_TOKEN="your_databricks_pat"
export WAREHOUSE_ID="4b28691c780d9875"

# Optional
export CATALOG_NAME="hls_amer_catalog"
export ENVIRONMENT="production"
```

## Documentation

- **README.md** (this file): Complete project overview
- **[DEMO_GUIDE.md](DEMO_GUIDE.md)**: Step-by-step demo walkthrough
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)**: Executive summary for stakeholders
- **[DEPLOYMENT.md](DEPLOYMENT.md)**: Detailed deployment instructions

## Key Deliverables

### Code Metrics
- **SQL**: 3 pipeline files (Bronze, Silver, Gold)
- **Backend**: 462 lines of FastAPI code (14 endpoints)
- **Frontend**: 1,949 lines across 7 React components
- **Dashboards**: 1,183 lines of SQL queries (40 queries)
- **Total**: 3,500+ lines of production code

### Data Volumes
- **Patients**: 15,000 synthetic records
- **Encounters**: 50,362 visits
- **Claims**: 48,362 billing records
- **Lab Results**: 45,000 test results
- **Denials**: 11,628 denial records

### Features
- **API Endpoints**: 14 REST APIs
- **Dashboard Pages**: 5 interactive scenarios
- **Lakeview Queries**: 40 SQL analytics queries
- **Data Tables**: 19 total (7 Bronze, 7 Silver, 5 Gold)

## License

Proprietary - Renown Health RFP Demonstration

## Contact

For questions or support, please contact the development team.

---

**Built with**: Databricks • FastAPI • React • Material-UI • Delta Lake
**Status**: Production Ready - All 11 Phases Complete
**Last Updated**: November 2025
