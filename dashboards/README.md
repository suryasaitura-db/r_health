# R_Health Databricks AI/BI Dashboards

This directory contains resources for creating and managing Databricks AI/BI (Lakeview) dashboards for the R_Health Healthcare Analytics Platform.

## Overview

Five comprehensive dashboards covering all healthcare analytics scenarios:

1. **Capacity Management** - Optimize hospital capacity and reduce length of stay
2. **Denials Management** - Track denial rates, appeals, and revenue recovery
3. **Clinical Trial Matching** - Identify eligible patients for clinical trials
4. **Timely Filing & Appeals** - Monitor claims at risk of timely filing deadlines
5. **Documentation Management** - Track documentation requests and turnaround times

## Directory Structure

```
dashboards/
├── README.md                           # This file
├── queries/                            # SQL queries for dashboard visualizations
│   ├── 01_capacity_management.sql      # 8 queries for Capacity Management dashboard
│   ├── 02_denials_management.sql       # 8 queries for Denials Management dashboard
│   ├── 03_clinical_trials.sql          # 8 queries for Clinical Trial Matching dashboard
│   ├── 04_timely_filing.sql            # 8 queries for Timely Filing & Appeals dashboard
│   └── 05_documentation.sql            # 9 queries for Documentation Management dashboard
```

## Creating Dashboards

### Option 1: Automated Creation (Recommended)

Run the automated dashboard creation script from the project root:

```bash
python create_lakeview_dashboards.py
```

This will:
- Create 5 empty Lakeview dashboards in your Databricks workspace
- Configure the SQL warehouse for each dashboard
- Display dashboard IDs and paths

### Option 2: Manual Creation via UI

1. Log into Databricks workspace
2. Navigate to **Dashboards** in the left sidebar
3. Click **Create Dashboard**
4. Select **Lakeview Dashboard**
5. Choose SQL warehouse: `4b28691c780d9875`
6. Name the dashboard (e.g., "R_Health - Capacity Management")

## Adding Visualizations to Dashboards

After creating the dashboards, add visualizations using the SQL queries:

### Step 1: Open Dashboard

1. Go to **Dashboards** in Databricks
2. Find your R_Health dashboard (e.g., "R_Health - Capacity Management")
3. Click **Edit** to enter edit mode

### Step 2: Add Visualization

1. Click **Add** → **Visualization**
2. Copy SQL query from the appropriate file in `queries/`
3. Paste into the query editor
4. Run the query to preview data
5. Select visualization type:
   - **Counter** - For KPI metrics (summary queries)
   - **Bar Chart** - For comparisons and rankings
   - **Pie Chart** - For distribution analyses
   - **Line Chart** - For trends over time
   - **Table** - For detailed data views

### Step 3: Configure Visualization

1. Set chart title and description
2. Configure axes, colors, and formatting
3. Add filters if needed (payer, date range, etc.)
4. Position the visualization on the canvas

### Step 4: Publish Dashboard

1. Click **Publish** when all visualizations are added
2. Set permissions for viewers
3. Share the dashboard URL

## Query Files Overview

### 01_capacity_management.sql (8 queries, 194 lines)

**KPIs:**
- `capacity_kpi_summary` - Total encounters, bed days, cost opportunities

**Analytics:**
- `top_cost_opportunities` - Top 10 DRGs by cost savings potential
- `priority_distribution` - Distribution by optimization priority
- `los_performance_analysis` - Actual vs benchmark LOS comparison
- `volume_opportunity_matrix` - Volume vs cost opportunity segmentation
- `bed_days_utilization` - Excess bed days analysis
- `detailed_capacity_data` - Comprehensive drill-down table
- `drg_category_summary` - Opportunities by DRG category

**Recommended Visualizations:**
- Counter cards for KPIs
- Horizontal bar chart for top opportunities
- Pie chart for priority distribution
- Scatter plot for volume vs opportunity matrix

### 02_denials_management.sql (8 queries, 206 lines)

**KPIs:**
- `denials_kpi_summary` - Denials, appeals, recovery rates

**Analytics:**
- `top_denial_categories` - Root cause analysis
- `payer_performance_ranking` - Payer-specific metrics
- `denial_rate_distribution` - Performance tier distribution
- `appeal_success_analysis` - Win rates by category/payer
- `high_priority_denials` - Action list for high-priority denials
- `recovery_opportunities` - Low recovery + high dollar potential
- `payer_category_matrix` - Denial patterns by payer-category

**Recommended Visualizations:**
- Counter cards for KPIs
- Bar chart for top denial categories
- Table for payer performance ranking
- Heatmap for payer-category matrix

### 03_clinical_trials.sql (8 queries, 244 lines)

**KPIs:**
- `trial_matching_kpi_summary` - Eligibility metrics across trials

**Analytics:**
- `trial_type_distribution` - KRAS, COPD, PDL1 eligibility
- `age_distribution_analysis` - Age demographics
- `diagnosis_trial_opportunities` - Diagnoses with highest potential
- `multi_trial_eligible_patients` - Multi-trial eligible patients
- `gender_eligibility_analysis` - Gender diversity
- `biomarker_positive_patients` - Detailed patient list
- `eligibility_funnel_analysis` - Diagnosis to eligibility conversion

**Recommended Visualizations:**
- Counter cards for KPIs
- Bar chart for trial type distribution
- Histogram for age distribution
- Funnel chart for eligibility funnel

### 04_timely_filing.sql (8 queries, 255 lines)

**KPIs:**
- `timely_filing_kpi_summary` - Filing risk and compliance overview

**Analytics:**
- `compliance_status_breakdown` - Critical/Warning/Compliant distribution
- `payer_risk_ranking` - Payers with highest filing risk
- `critical_claims_action_list` - Immediate action items
- `deadline_timeline_distribution` - Claims by days to deadline
- `revenue_risk_quantification` - Financial exposure
- `urgency_score_prioritization` - Composite urgency scoring
- `detailed_filing_tracker` - Comprehensive tracking table

**Recommended Visualizations:**
- Counter cards for KPIs
- Pie chart for compliance status
- Bar chart for payer risk ranking
- Table for critical claims action list

### 05_documentation.sql (9 queries, 284 lines)

**KPIs:**
- `documentation_kpi_summary` - Documentation performance overview

**Analytics:**
- `doc_type_performance` - Completion by doc type
- `payer_documentation_analysis` - Payer-specific burden
- `urgency_level_breakdown` - Resource prioritization
- `turnaround_time_analysis` - Process bottleneck identification
- `completion_rate_tiers` - Performance segmentation
- `high_value_documentation_tracking` - High-value claims focus
- `detailed_documentation_tracker` - Comprehensive operational view
- `payer_doctype_matrix` - Payer-specific patterns

**Recommended Visualizations:**
- Counter cards for KPIs
- Bar chart for doc type performance
- Table for payer analysis
- Heatmap for payer-doctype matrix

## Dashboard Features

All queries include:

- **Business value comments** - Clear explanation of insights
- **Performance optimization** - Efficient aggregations and filters
- **Dashboard-ready formatting** - Easy Lakeview integration
- **Actionable insights** - Priority rankings and drill-downs
- **Comprehensive coverage** - KPIs, trends, distributions, details

## Data Sources

All queries use the Gold layer tables:

- `hls_amer_catalog.r_health_gold.capacity_management`
- `hls_amer_catalog.r_health_gold.denials_management`
- `hls_amer_catalog.r_health_gold.clinical_trial_matching`
- `hls_amer_catalog.r_health_gold.timely_filing_appeals`
- `hls_amer_catalog.r_health_gold.documentation_management`

## Publishing Dashboards

Once visualizations are added:

1. Click **Publish** in the dashboard editor
2. Add a publication message (e.g., "Initial R_Health Analytics Dashboard")
3. Set permissions:
   - **CAN_MANAGE**: Admins and dashboard creators
   - **CAN_RUN**: Healthcare analysts and managers
   - **CAN_VIEW**: Executive stakeholders
4. Share the published dashboard URL

## Best Practices

1. **Start with KPIs**: Add summary metrics first (counter cards at top)
2. **Add context**: Follow KPIs with trend charts and distributions
3. **Enable drill-down**: Include detailed tables for investigation
4. **Use filters**: Add date range, payer, or priority filters
5. **Test performance**: Ensure queries run quickly (< 5 seconds)
6. **Refresh schedules**: Set up automated refreshes for latest data
7. **Mobile-friendly**: Test dashboards on different screen sizes

## Troubleshooting

### Dashboard won't load
- Verify SQL warehouse is running (`4b28691c780d9875`)
- Check Unity Catalog permissions for `hls_amer_catalog`
- Ensure Gold layer tables exist

### Query errors
- Verify table names match: `hls_amer_catalog.r_health_gold.*`
- Check column names match Gold layer schema
- Test queries in SQL Editor first

### Slow performance
- Add filters to limit data volume
- Use summary queries instead of detailed tables
- Check warehouse scaling settings

## Support

For issues:
1. Check Gold layer tables: `sql/03_gold/03_silver_to_gold_business_datasets.sql`
2. Verify API endpoints: `backend/main.py` or `backend/app_main.py`
3. Review deployment: `DEPLOYMENT.md`

---

**Total Queries**: 40 optimized SQL queries
**Total Lines**: 1,183 lines of SQL code
**Ready for**: Databricks AI/BI Lakeview Dashboards
