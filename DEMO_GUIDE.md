# R_Health Platform Demo Guide

A comprehensive step-by-step guide for demonstrating the R_Health Healthcare Analytics Platform to stakeholders, technical teams, and business users.

## Table of Contents
- [Demo Overview](#demo-overview)
- [Prerequisites](#prerequisites)
- [Demo Setup](#demo-setup)
- [Demo Flow](#demo-flow)
- [Scenario Walkthroughs](#scenario-walkthroughs)
- [API Demonstrations](#api-demonstrations)
- [Dashboard Demonstrations](#dashboard-demonstrations)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

## Demo Overview

### Demo Objectives
1. Showcase end-to-end healthcare analytics capabilities
2. Demonstrate Medallion architecture (Bronze → Silver → Gold)
3. Highlight modern web application (React + FastAPI)
4. Present AI/BI dashboard capabilities
5. Prove production-ready deployment on Databricks Apps

### Target Audience
- **Executive Leadership**: Business value, ROI, strategic impact
- **Clinical Operations**: Practical use cases, workflow integration
- **IT/Technical Teams**: Architecture, scalability, maintainability
- **Data Analytics Teams**: Data quality, metrics, insights

### Demo Duration
- **Quick Demo**: 15 minutes (high-level overview + 1 scenario)
- **Standard Demo**: 30 minutes (overview + 3 scenarios + API)
- **Comprehensive Demo**: 60 minutes (all 5 scenarios + architecture + dashboards)

## Prerequisites

### Access Requirements
- Databricks workspace access
- Unity Catalog permissions for `hls_amer_catalog`
- SQL Serverless Warehouse access (ID: `4b28691c780d9875`)
- Databricks Apps access (for production demo)

### Local Development Setup (Optional)
```bash
# Environment variables
export DATABRICKS_TOKEN="your_databricks_pat"
export WAREHOUSE_ID="4b28691c780d9875"

# Python dependencies
pip install fastapi uvicorn databricks-sdk

# Node.js dependencies
cd frontend && npm install
```

### Data Verification
Before starting the demo, verify data is loaded:

```sql
-- Check Bronze layer
SELECT COUNT(*) as patient_count FROM hls_amer_catalog.r_health_bronze.patients;
-- Expected: 15,000

SELECT COUNT(*) as encounter_count FROM hls_amer_catalog.r_health_bronze.encounters;
-- Expected: 50,362

-- Check Gold layer
SELECT COUNT(*) as capacity_records FROM hls_amer_catalog.r_health_gold.capacity_management;
-- Expected: 157 DRG codes

SELECT COUNT(*) as trial_eligible FROM hls_amer_catalog.r_health_gold.clinical_trial_matching;
-- Expected: 847 eligible patients
```

## Demo Setup

### Option 1: Databricks Apps (Recommended for Demos)
1. Navigate to Databricks workspace
2. Go to "Apps" section
3. Launch "r-health-analytics" app
4. Note the app URL for sharing with stakeholders

### Option 2: Local Development
```bash
# Terminal 1 - Backend API
cd backend
python main.py
# Access: http://localhost:8000

# Terminal 2 - Frontend App
cd frontend
npm run dev
# Access: http://localhost:5173
```

### Demo Data Quick Reference
| Metric | Value |
|--------|-------|
| Total Patients | 15,000 |
| Total Encounters | 50,362 |
| Total Claims | 48,362 |
| Denied Claims | 11,628 |
| At-Risk Claims | 1,694 |
| Trial Eligible Patients | 847 |
| DRG Codes | 157 |
| Cost Opportunity | $2.5M+ |

## Demo Flow

### 1. Introduction (3 minutes)

**Opening Statement**:
> "Today I'll demonstrate the R_Health Healthcare Analytics Platform - a comprehensive solution that processes 15,000 patients and 50,000+ encounters across five critical healthcare scenarios. This platform showcases how Databricks enables modern healthcare analytics through a Medallion architecture, RESTful APIs, and interactive dashboards."

**Show Architecture Diagram**:
```
Bronze (Raw Data) → Silver (Cleansed) → Gold (Analytics) → Applications
   15K patients       Business logic      5 scenarios      React + API
   50K encounters     Data quality        KPIs calculated  Dashboards
```

**Key Talking Points**:
- Production-ready, enterprise-grade solution
- 3,500+ lines of code across SQL, Python, React
- Real-world healthcare use cases
- Scalable Databricks architecture

### 2. Data Pipeline Overview (5 minutes)

**Navigate to Databricks SQL Editor**

**Bronze Layer Demonstration**:
```sql
-- Show raw patient data with biomarkers
SELECT
    patient_id,
    age,
    gender,
    primary_diagnosis,
    has_kras_g12c_mutation,
    has_copd,
    insurance_type
FROM hls_amer_catalog.r_health_bronze.patients
LIMIT 10;
```

**Talking Points**:
- Synthetic data generated with realistic healthcare patterns
- KRAS mutations, COPD diagnoses, lab results (FEV1, PD-L1)
- Payer mix: 40% Medicare, 30% Medicaid, 30% Commercial

**Silver Layer Demonstration**:
```sql
-- Show cleansed encounter data with calculated LOS
SELECT
    encounter_id,
    patient_id,
    encounter_type,
    drg_code,
    admission_date,
    discharge_date,
    length_of_stay,
    total_charges,
    is_readmission_30_day
FROM hls_amer_catalog.r_health_silver.encounters_clean
WHERE encounter_type = 'Inpatient'
ORDER BY length_of_stay DESC
LIMIT 10;
```

**Talking Points**:
- Business logic applied (LOS calculation, readmission flags)
- Data quality improvements
- Enrichment with derived fields

**Gold Layer Demonstration**:
```sql
-- Show analytics-ready capacity management data
SELECT
    drg_code,
    primary_diagnosis_code,
    total_encounters,
    avg_los,
    gmlos_benchmark,
    avg_los_variance,
    estimated_cost_opportunity,
    optimization_priority
FROM hls_amer_catalog.r_health_gold.capacity_management
ORDER BY estimated_cost_opportunity DESC
LIMIT 10;
```

**Talking Points**:
- Aggregated business metrics
- Priority scoring algorithms
- Action-oriented insights

### 3. Application Overview (2 minutes)

**Launch React Application** (Databricks App or localhost:5173)

**Home Page Walkthrough**:
- Point out the 5 scenario cards
- Highlight the clean, professional UI
- Note the responsive Material-UI design
- Show the navigation structure

**Talking Points**:
- Modern React 18 application
- Material-UI enterprise design system
- 1,949 lines of React code
- Real-time API integration

## Scenario Walkthroughs

### Scenario 1: Capacity Management (7 minutes)

**Navigate to**: Capacity Management page

**Demo Script**:

1. **Overview Section**
   - "This dashboard shows 157 DRG codes with $2.5M in identified cost opportunities"
   - Point to the KPI cards showing total encounters, avg LOS, cost opportunity

2. **Priority Distribution**
   - "We automatically categorize DRGs by priority: 23 Critical, 47 High, 87 Low"
   - Explain the priority logic: LOS variance + encounter volume

3. **Top Opportunities Table**
   - Sort by "Cost Opportunity" (descending)
   - "DRG 470 (Major Hip/Knee Joint Replacement) shows the highest opportunity"
   - Click on a high-variance DRG
   - Explain: "Average LOS of 7.2 days vs GMLOS benchmark of 2.8 days = 4.4 excess days"

4. **LOS Variance Chart**
   - "This visualization shows which DRGs deviate most from national benchmarks"
   - Point to DRGs above the benchmark line

**Key Business Value**:
> "By identifying DRGs with high LOS variance, clinical teams can focus on care pathway optimization, reducing excess bed days and improving throughput. This translates to real cost savings and better patient flow."

**Sample Queries to Discuss**:
```sql
-- Find DRGs with highest excess days
SELECT
    drg_code,
    primary_diagnosis_code,
    total_encounters,
    excess_days,
    estimated_cost_opportunity
FROM hls_amer_catalog.r_health_gold.capacity_management
WHERE optimization_priority LIKE '%Critical%'
ORDER BY excess_days DESC
LIMIT 5;
```

### Scenario 2: Denials Management (7 minutes)

**Navigate to**: Denials Management page

**Demo Script**:

1. **Summary Metrics**
   - "11,628 denied claims totaling $1.8M"
   - "5,814 appeals filed with 77.3% win rate"
   - "$894K recovered through successful appeals"

2. **Denial Categories**
   - Show pie chart of denial reasons
   - "Authorization Required: 25% of denials"
   - "Medical Necessity: 24%"
   - "Coding Error: 20%"

3. **Payer Analysis**
   - Filter by payer (e.g., "Medicare")
   - "Medicare shows 3,200+ denials but 82% appeal success rate"
   - Compare with Medicaid or Commercial payers

4. **High-Priority Appeals**
   - Sort by Priority Score (descending)
   - "This table helps teams focus on high-value appeals"
   - Show a denial with high amount + high win rate

**Key Business Value**:
> "By prioritizing appeals based on both financial impact and win probability, revenue cycle teams can maximize recovery rates. The $894K already recovered represents a 49% success rate with significant upside remaining."

**Sample Data Points to Highlight**:
- Average denial age: Track how long claims sit in denial status
- Win rate by payer: Some payers are more likely to overturn
- Partial recoveries: Even partial wins add revenue

### Scenario 3: Clinical Trial Matching (7 minutes)

**Navigate to**: Clinical Trials page

**Demo Script**:

1. **Trial Overview**
   - "847 patients eligible across 3 precision medicine trials"
   - "KRAS G12C trial: 283 eligible patients"
   - "COPD trial: 292 eligible patients"
   - "PD-L1 trial: 284 eligible patients"

2. **KRAS Trial Deep Dive**
   - Click on KRAS trial tab or filter
   - "Eligibility: NSCLC diagnosis + KRAS G12C mutation + Age 18-85"
   - Show patient list with biomarker status

3. **Multi-Trial Eligible Patients**
   - "12 patients eligible for multiple trials"
   - "These represent high-priority recruitment opportunities"

4. **Patient Details**
   - Click on a high-priority patient
   - Show: diagnosis, biomarker status, age, trial eligibility flags

**Key Business Value**:
> "Clinical trial matching accelerates enrollment for precision medicine studies. By automatically identifying eligible patients from EHR and lab data, research teams can reduce screening time from weeks to minutes."

**Technical Highlight**:
```sql
-- Complex eligibility logic in Gold layer
-- KRAS Trial: NSCLC + KRAS G12C + Age 18-85
-- COPD Trial: COPD + FEV1 30-60% + Age 40-80
-- PD-L1 Trial: NSCLC + PD-L1 >50% + No prior immunotherapy
```

### Scenario 4: Timely Filing & Appeals (7 minutes)

**Navigate to**: Timely Filing page

**Demo Script**:

1. **Compliance Overview**
   - "48,362 claims monitored for 180-day filing deadlines"
   - "1,694 at-risk claims (within 30 days of deadline)"
   - "$1.9M at risk of timely filing denial"

2. **Urgency Dashboard**
   - Show urgency distribution: Critical, High, Medium, Low
   - "Critical urgency: Claims with <15 days to deadline"
   - Filter to Critical urgency

3. **At-Risk Claims Table**
   - Sort by "Days to Deadline" (ascending)
   - "This claim has 8 days remaining - requires immediate action"
   - Show urgency score calculation

4. **Deadline Trends**
   - Show histogram of days to deadline
   - "Most claims are safely within deadline, but we have a tail of high-risk items"

**Key Business Value**:
> "Timely filing is a leading cause of preventable denials. By monitoring deadlines and prioritizing at-risk claims, revenue cycle teams can prevent revenue loss before it occurs. The $1.9M at-risk amount represents real dollars that can be protected."

**Urgency Scoring Explained**:
- Score 90-100: <15 days, Critical priority
- Score 70-89: 15-30 days, High priority
- Score 40-69: 30-60 days, Medium priority
- Score 0-39: >60 days, Low priority

### Scenario 5: Documentation Management (7 minutes)

**Navigate to**: Documentation Management page

**Demo Script**:

1. **Request Overview**
   - "2,400 documentation requests tracked"
   - "1,680 completed (70% completion rate)"
   - "8.4 days average turnaround time"
   - "$34.2M in associated claim value"

2. **Request Types**
   - Medical Records Review: Most common
   - CDI (Clinical Documentation Improvement)
   - Authorization Documentation
   - Appeal Support

3. **SLA Compliance**
   - "72.3% overall SLA compliance"
   - Show breakdown by request type
   - Identify which types have lowest compliance

4. **Turnaround Time Analysis**
   - Show average turnaround by payer
   - "Some payers require faster response than others"
   - Filter to high-urgency requests

**Key Business Value**:
> "Documentation requests directly impact claim adjudication success. Fast, accurate responses reduce denials and support appeals. The $34.2M in associated claim value shows the financial impact of efficient documentation workflows."

**Sample Insights**:
- Requests with high urgency + high claim value = top priority
- Turnaround time trends identify process bottlenecks
- Completion rate by request type shows training opportunities

## API Demonstrations

### FastAPI Interactive Documentation

**Navigate to**: `http://localhost:8000/docs` (or Databricks App URL + `/docs`)

**Demo Script**:

1. **API Overview**
   - "14 REST API endpoints for programmatic access"
   - "Swagger/OpenAPI documentation auto-generated"
   - "Easy integration with other systems"

2. **Try Out Capacity Management API**
   ```
   GET /api/capacity-management/summary
   ```
   - Click "Try it out" → "Execute"
   - Show JSON response with summary statistics
   - Explain each field in the response

3. **Filtered API Call**
   ```
   GET /api/denials-management?payer=Medicare&limit=20
   ```
   - Set parameters: payer=Medicare, limit=20
   - Execute and show filtered results
   - Demonstrate the flexibility of filters

4. **Clinical Trial Matching API**
   ```
   GET /api/clinical-trial-matching?trial_type=KRAS&eligible_only=true
   ```
   - Show how to get only eligible patients for specific trial
   - Explain boolean parameters

**Command-Line API Examples**:

```bash
# Health check
curl http://localhost:8000/health

# Get capacity summary
curl http://localhost:8000/api/capacity-management/summary | jq

# Get critical capacity issues
curl "http://localhost:8000/api/capacity-management?priority=Critical&limit=10" | jq

# Get Medicare denials
curl "http://localhost:8000/api/denials-management?payer=Medicare" | jq

# Get KRAS eligible patients
curl "http://localhost:8000/api/clinical-trial-matching?trial_type=KRAS&eligible_only=true" | jq

# Get critical urgency filing claims
curl "http://localhost:8000/api/timely-filing-appeals?urgency=Critical" | jq
```

**Integration Talking Points**:
- APIs enable integration with Epic, Cerner, or other EHR systems
- Can feed data to BI tools (Tableau, Power BI)
- Support for batch and real-time queries
- RESTful design follows industry standards

## Dashboard Demonstrations

### Databricks AI/BI Lakeview Dashboards

**Navigate to**: Databricks workspace → Dashboards → Lakeview

**Demo Script**:

1. **Dashboard Overview**
   - "40 SQL queries across 5 dashboard configurations"
   - "1,183 lines of optimized SQL"
   - "Real-time connection to Gold layer tables"

2. **Capacity Management Dashboard**

   **Query 1: High-Priority DRGs**
   ```sql
   SELECT
       drg_code,
       primary_diagnosis_code,
       total_encounters,
       avg_los,
       gmlos_benchmark,
       estimated_cost_opportunity,
       optimization_priority
   FROM hls_amer_catalog.r_health_gold.capacity_management
   WHERE optimization_priority LIKE '%Critical%'
       OR optimization_priority LIKE '%High%'
   ORDER BY estimated_cost_opportunity DESC
   LIMIT 20;
   ```

   **Show**: Bar chart of cost opportunity by DRG

   **Query 2: LOS Variance Trend**
   - Visualize DRGs with highest variance
   - Compare actual LOS vs benchmark
   - Show as scatter plot or line chart

3. **Denials Dashboard**

   **Query 1: Denial Category Breakdown**
   ```sql
   SELECT
       denial_category,
       SUM(total_denials) as denial_count,
       SUM(total_denied_amount) as denied_amount,
       AVG(appeal_win_rate) as avg_win_rate
   FROM hls_amer_catalog.r_health_gold.denials_management
   GROUP BY denial_category
   ORDER BY denied_amount DESC;
   ```

   **Show**: Pie chart of denials by category, bar chart of amounts

   **Query 2: Payer Performance**
   - Win rate by payer
   - Recovery amount by payer
   - Show as stacked bar chart

4. **Clinical Trials Dashboard**

   **Query: Multi-Trial Eligible Patients**
   ```sql
   SELECT
       patient_id,
       age,
       gender,
       primary_diagnosis,
       kras_trial_eligible,
       copd_trial_eligible,
       pdl1_trial_eligible,
       eligible_trial_count,
       trial_match_priority
   FROM hls_amer_catalog.r_health_gold.clinical_trial_matching
   WHERE eligible_trial_count > 1
   ORDER BY trial_match_priority DESC;
   ```

   **Show**: Table of high-priority patients, eligibility matrix

5. **Interactive Features**
   - Filters: Date ranges, payers, DRGs, urgency levels
   - Drill-downs: Click on a chart to see details
   - Exports: Download as PDF, CSV, or Excel
   - Scheduling: Email reports on schedule

**Lakeview Advantages**:
- No separate BI tool needed
- Direct connection to Delta Lake (no ETL)
- Governed by Unity Catalog
- Collaborative sharing within Databricks

## Troubleshooting

### Common Issues and Solutions

#### 1. No Data Showing in Tables

**Symptom**: API returns empty arrays, React tables show "No data"

**Solution**:
```sql
-- Verify Gold layer tables exist and have data
SHOW TABLES IN hls_amer_catalog.r_health_gold;

SELECT COUNT(*) FROM hls_amer_catalog.r_health_gold.capacity_management;
```

If count is 0, re-run Gold layer:
```bash
python3 execute_gold_layer_sdk.py
```

#### 2. API Connection Error

**Symptom**: "Failed to fetch" or "Network error" in React app

**Check**:
1. Backend is running: `curl http://localhost:8000/health`
2. CORS is configured (already done in code)
3. Firewall isn't blocking port 8000

**Solution**:
```bash
# Restart backend
cd backend
export DATABRICKS_TOKEN="your_token"
export WAREHOUSE_ID="4b28691c780d9875"
python main.py
```

#### 3. Slow Query Performance

**Symptom**: API calls take >5 seconds

**Solution**:
- Ensure SQL Serverless Warehouse is running (not stopped)
- Check warehouse size (may need to scale up for demo)
- Verify no concurrent heavy queries

#### 4. Frontend Build Errors

**Symptom**: `npm run dev` fails

**Solution**:
```bash
# Clear cache and reinstall
cd frontend
rm -rf node_modules package-lock.json
npm install
npm run dev
```

#### 5. Databricks Apps Deployment Fails

**Symptom**: `deploy_to_databricks.py` errors

**Solution**:
1. Check Databricks CLI authentication
2. Verify app.yaml is correct
3. Ensure frontend is built: `python3 build.py`
4. Check Databricks Apps permissions

### Performance Optimization Tips

**For Large Demos**:
1. Pre-warm the warehouse: Run a simple query before demo starts
2. Keep browser tabs organized: Only open what you need
3. Refresh data periodically: Gold layer queries are fast
4. Use filters to limit result sets: Faster rendering

**For API Demos**:
1. Use `limit` parameter to control result size
2. Test API calls before demo to verify response times
3. Have example `curl` commands ready to copy-paste

## FAQ

### General Questions

**Q: Is this real patient data?**
A: No, all data is synthetically generated for demonstration purposes. The patterns and distributions are realistic but contain no actual PHI.

**Q: How long did it take to build this platform?**
A: The complete platform represents 11 phases of development, including:
- Data pipeline (Bronze, Silver, Gold)
- Backend API (14 endpoints)
- Frontend application (5 scenarios)
- Dashboards (40 queries)
- Deployment infrastructure

**Q: Can this handle more patients?**
A: Yes, the architecture scales horizontally. The Medallion pattern and Databricks infrastructure support millions of patients.

**Q: How often does data refresh?**
A: Currently using static synthetic data. In production, Bronze layer would refresh nightly or real-time, Silver/Gold would update on schedule or trigger.

### Technical Questions

**Q: Why Medallion architecture?**
A: Bronze (raw) → Silver (cleansed) → Gold (analytics) provides:
- Separation of concerns
- Reproducible transformations
- Incremental complexity
- Easy debugging and data lineage

**Q: Why FastAPI instead of Django or Flask?**
A: FastAPI offers:
- Automatic OpenAPI documentation
- Type safety with Pydantic
- Async support for high performance
- Modern Python 3.9+ features

**Q: Why React instead of Angular or Vue?**
A: React provides:
- Large ecosystem (Material-UI, Recharts)
- Strong community support
- Component reusability
- Industry standard for enterprise apps

**Q: How are APIs secured?**
A: In this demo, authentication is via Databricks token. For production:
- OAuth 2.0 or SAML integration
- Role-based access control (RBAC)
- Unity Catalog governance
- Network security groups

### Business Questions

**Q: What's the ROI of this platform?**
A: Based on identified opportunities:
- $2.5M in capacity optimization
- $894K in denial recoveries (with $900K+ remaining)
- $1.9M protected from timely filing denials
- 847 patients for clinical trial enrollment

Total potential value: $5M+ annually

**Q: How long to deploy in production?**
A:
- Data integration (Bronze layer): 2-4 weeks
- Customization for your workflows: 2-3 weeks
- Testing and validation: 1-2 weeks
- Training and rollout: 1 week

Total: 6-10 weeks for production deployment

**Q: Can this integrate with our EHR (Epic, Cerner)?**
A: Yes, the Bronze layer can connect to EHR APIs or data exports:
- Epic: FHIR APIs, Clarity database
- Cerner: MillenniumObjects, FHIR
- Other: HL7, FHIR, or bulk exports

**Q: What about HIPAA compliance?**
A: Databricks supports HIPAA compliance:
- Unity Catalog governance
- Encryption at rest and in transit
- Audit logging
- BAA available from Databricks

### Demo-Specific Questions

**Q: Can I filter by date range?**
A: The demo uses static data without date filters, but production version would include:
- Encounter date ranges
- Claim submission date ranges
- Denial aging filters
- Rolling 30/60/90 day views

**Q: Can I export this data?**
A: Yes, multiple options:
- API: JSON format for programmatic access
- Lakeview: PDF, CSV, Excel exports
- SQL: Direct query exports
- React app: Add export buttons (not currently implemented)

**Q: How do I access the Databricks Apps version?**
A:
1. Navigate to your Databricks workspace
2. Go to "Apps" in left navigation
3. Find "r-health-analytics"
4. Click to launch
5. Share the URL with stakeholders (requires Databricks login)

---

## Demo Checklist

### Before the Demo
- [ ] Verify data is loaded (run verification queries)
- [ ] Test backend API health check
- [ ] Load React app and verify all 5 pages render
- [ ] Check Lakeview dashboards are accessible
- [ ] Prepare screen sharing / presentation mode
- [ ] Close unnecessary browser tabs
- [ ] Have code repository ready to show
- [ ] Prepare questions you anticipate

### During the Demo
- [ ] Start with business value, not technology
- [ ] Use real numbers from the data
- [ ] Show, don't just tell (click through the app)
- [ ] Relate to audience's pain points
- [ ] Pause for questions throughout
- [ ] Keep technical depth appropriate for audience
- [ ] Demonstrate API if technical audience

### After the Demo
- [ ] Share demo link (Databricks App URL)
- [ ] Send follow-up documentation
- [ ] Provide API documentation link
- [ ] Schedule follow-up for questions
- [ ] Collect feedback

---

**Ready to Demo?** Start with the [Demo Flow](#demo-flow) section and follow the script for your audience type.

**Questions?** Refer to the [Troubleshooting](#troubleshooting) and [FAQ](#faq) sections.

**Last Updated**: November 2025
