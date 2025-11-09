"""
R_Health FastAPI Backend - Renown Health RFP Demo
Provides REST API endpoints for all 5 healthcare analytics scenarios
"""
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from databricks.sdk import WorkspaceClient
from typing import List, Dict, Any, Optional
import os

app = FastAPI(
    title="R_Health Healthcare Analytics API",
    description="FastAPI backend for Renown Health RFP demo - 5 healthcare analytics scenarios",
    version="1.0.0"
)

# CORS middleware for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Databricks configuration
w = WorkspaceClient()
WAREHOUSE_ID = os.getenv("WAREHOUSE_ID", "4b28691c780d9875")


def execute_query(query: str) -> List[Dict[str, Any]]:
    """Execute SQL query and return results as list of dictionaries"""
    try:
        response = w.statement_execution.execute_statement(
            warehouse_id=WAREHOUSE_ID,
            statement=query,
            wait_timeout="50s"
        )

        if not response.result or not response.result.data_array:
            return []

        # Get column names
        columns = [col.name for col in response.result.manifest.schema.columns]

        # Convert rows to dictionaries
        results = []
        for row in response.result.data_array:
            results.append(dict(zip(columns, row)))

        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database query error: {str(e)}")


@app.get("/")
def read_root():
    """Root endpoint - API information"""
    return {
        "name": "R_Health Healthcare Analytics API",
        "version": "1.0.0",
        "scenarios": [
            "Capacity Management",
            "Denials Management",
            "Clinical Trial Matching",
            "Timely Filing & Appeals",
            "Documentation Management"
        ],
        "endpoints": {
            "capacity_management": "/api/capacity-management",
            "denials_management": "/api/denials-management",
            "clinical_trial_matching": "/api/clinical-trial-matching",
            "timely_filing_appeals": "/api/timely-filing-appeals",
            "documentation_management": "/api/documentation-management"
        }
    }


@app.get("/health")
def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "R_Health API"}


# ==============================================================================
# SCENARIO 1: CAPACITY MANAGEMENT
# ==============================================================================

@app.get("/api/capacity-management")
def get_capacity_management(
    priority: Optional[str] = Query(None, description="Filter by priority: Critical, High, Low"),
    min_encounters: Optional[int] = Query(None, description="Minimum number of encounters"),
    limit: Optional[int] = Query(100, description="Maximum results to return")
):
    """
    Get capacity management analytics - bed utilization & LOS optimization
    """
    query = """
    SELECT
        drg_code,
        primary_diagnosis_code,
        total_encounters,
        unique_patients,
        avg_los,
        gmlos_benchmark,
        avg_los_variance,
        median_los,
        p90_los,
        total_bed_days,
        high_variance_count,
        excess_days,
        estimated_cost_opportunity,
        optimization_priority
    FROM hls_amer_catalog.r_health_gold.capacity_management
    WHERE 1=1
    """

    if priority:
        query += f" AND optimization_priority LIKE '%{priority}%'"

    if min_encounters:
        query += f" AND total_encounters >= {min_encounters}"

    query += f" ORDER BY estimated_cost_opportunity DESC LIMIT {limit}"

    return execute_query(query)


@app.get("/api/capacity-management/summary")
def get_capacity_summary():
    """Get summary statistics for capacity management"""
    query = """
    SELECT
        COUNT(*) as total_drgs,
        SUM(total_encounters) as total_encounters,
        SUM(total_bed_days) as total_bed_days,
        ROUND(AVG(avg_los), 2) as overall_avg_los,
        SUM(estimated_cost_opportunity) as total_cost_opportunity,
        SUM(CASE WHEN optimization_priority LIKE '%Critical%' THEN 1 ELSE 0 END) as critical_count,
        SUM(CASE WHEN optimization_priority LIKE '%High%' THEN 1 ELSE 0 END) as high_priority_count,
        SUM(CASE WHEN optimization_priority LIKE '%Low%' THEN 1 ELSE 0 END) as low_priority_count
    FROM hls_amer_catalog.r_health_gold.capacity_management
    """

    results = execute_query(query)
    return results[0] if results else {}


# ==============================================================================
# SCENARIO 2: DENIALS MANAGEMENT
# ==============================================================================

@app.get("/api/denials-management")
def get_denials_management(
    payer: Optional[str] = Query(None, description="Filter by payer name"),
    denial_category: Optional[str] = Query(None, description="Filter by denial category"),
    limit: Optional[int] = Query(100, description="Maximum results to return")
):
    """
    Get denials management analytics - appeal tracking & financial recovery
    """
    query = """
    SELECT
        payer_name,
        drg_code,
        primary_diagnosis_code,
        denial_category,
        total_denials,
        total_appealed,
        total_denied_amount,
        successful_appeals,
        partial_overturn_count,
        recovered_amount,
        partial_recovered_amount,
        appeal_win_rate,
        avg_denial_age,
        priority_score
    FROM hls_amer_catalog.r_health_gold.denials_management
    WHERE 1=1
    """

    if payer:
        query += f" AND payer_name = '{payer}'"

    if denial_category:
        query += f" AND denial_category = '{denial_category}'"

    query += f" ORDER BY priority_score DESC LIMIT {limit}"

    return execute_query(query)


@app.get("/api/denials-management/summary")
def get_denials_summary():
    """Get summary statistics for denials management"""
    query = """
    SELECT
        COUNT(*) as total_denial_groups,
        SUM(total_denials) as total_denials,
        SUM(total_appealed) as total_appealed,
        ROUND(SUM(total_denied_amount), 2) as total_denied_amount,
        ROUND(SUM(recovered_amount), 2) as total_recovered,
        ROUND(AVG(appeal_win_rate), 2) as avg_win_rate,
        ROUND(AVG(avg_denial_age), 1) as avg_denial_age_days
    FROM hls_amer_catalog.r_health_gold.denials_management
    """

    results = execute_query(query)
    return results[0] if results else {}


# ==============================================================================
# SCENARIO 3: CLINICAL TRIAL MATCHING
# ==============================================================================

@app.get("/api/clinical-trial-matching")
def get_clinical_trial_matching(
    trial_type: Optional[str] = Query(None, description="Filter by trial: KRAS, COPD, PDL1"),
    eligible_only: Optional[bool] = Query(False, description="Show only eligible patients"),
    limit: Optional[int] = Query(100, description="Maximum results to return")
):
    """
    Get clinical trial matching - patient eligibility for KRAS, COPD, PD-L1 trials
    """
    query = """
    SELECT
        patient_id,
        age,
        gender,
        primary_diagnosis,
        biomarker_status,
        kras_g12c_mutation,
        pdl1_expression_pct,
        latest_fev1,
        fev1_category,
        copd_severity,
        kras_trial_eligible,
        copd_trial_eligible,
        pdl1_trial_eligible,
        eligible_trial_count,
        trial_match_priority
    FROM hls_amer_catalog.r_health_gold.clinical_trial_matching
    WHERE 1=1
    """

    if eligible_only:
        query += " AND eligible_trial_count > 0"

    if trial_type:
        trial_type_upper = trial_type.upper()
        if trial_type_upper == "KRAS":
            query += " AND kras_trial_eligible = true"
        elif trial_type_upper == "COPD":
            query += " AND copd_trial_eligible = true"
        elif trial_type_upper == "PDL1":
            query += " AND pdl1_trial_eligible = true"

    query += f" ORDER BY eligible_trial_count DESC, trial_match_priority DESC LIMIT {limit}"

    return execute_query(query)


@app.get("/api/clinical-trial-matching/summary")
def get_clinical_trial_summary():
    """Get summary statistics for clinical trial matching"""
    query = """
    SELECT
        COUNT(*) as total_patients,
        SUM(CASE WHEN kras_trial_eligible THEN 1 ELSE 0 END) as kras_eligible,
        SUM(CASE WHEN copd_trial_eligible THEN 1 ELSE 0 END) as copd_eligible,
        SUM(CASE WHEN pdl1_trial_eligible THEN 1 ELSE 0 END) as pdl1_eligible,
        SUM(CASE WHEN eligible_trial_count > 1 THEN 1 ELSE 0 END) as multi_trial_eligible,
        ROUND(AVG(age), 1) as avg_patient_age
    FROM hls_amer_catalog.r_health_gold.clinical_trial_matching
    """

    results = execute_query(query)
    return results[0] if results else {}


# ==============================================================================
# SCENARIO 4: TIMELY FILING & APPEALS
# ==============================================================================

@app.get("/api/timely-filing-appeals")
def get_timely_filing_appeals(
    urgency: Optional[str] = Query(None, description="Filter by urgency: Critical, High, Medium, Low"),
    compliance_status: Optional[str] = Query(None, description="Filter by status"),
    limit: Optional[int] = Query(100, description="Maximum results to return")
):
    """
    Get timely filing & appeals - compliance deadlines & urgency scoring
    """
    query = """
    SELECT
        claim_id,
        patient_id,
        payer_name,
        drg_code,
        billed_amount,
        claim_submission_date,
        filing_deadline,
        days_to_deadline,
        compliance_status,
        is_at_risk,
        denial_status,
        denial_category,
        appeal_deadline,
        urgency_score,
        at_risk_amount,
        action_required
    FROM hls_amer_catalog.r_health_gold.timely_filing_appeals
    WHERE 1=1
    """

    if urgency:
        urgency_map = {
            "Critical": "urgency_score >= 90",
            "High": "urgency_score >= 70 AND urgency_score < 90",
            "Medium": "urgency_score >= 40 AND urgency_score < 70",
            "Low": "urgency_score < 40"
        }
        if urgency in urgency_map:
            query += f" AND {urgency_map[urgency]}"

    if compliance_status:
        query += f" AND compliance_status = '{compliance_status}'"

    query += f" ORDER BY urgency_score DESC, days_to_deadline ASC LIMIT {limit}"

    return execute_query(query)


@app.get("/api/timely-filing-appeals/summary")
def get_timely_filing_summary():
    """Get summary statistics for timely filing & appeals"""
    query = """
    SELECT
        COUNT(*) as total_claims,
        SUM(CASE WHEN is_at_risk THEN 1 ELSE 0 END) as at_risk_claims,
        SUM(CASE WHEN urgency_score >= 90 THEN 1 ELSE 0 END) as critical_urgency,
        SUM(CASE WHEN urgency_score >= 70 AND urgency_score < 90 THEN 1 ELSE 0 END) as high_urgency,
        ROUND(SUM(at_risk_amount), 2) as total_at_risk_amount,
        ROUND(AVG(days_to_deadline), 1) as avg_days_to_deadline,
        SUM(CASE WHEN denial_status IS NOT NULL THEN 1 ELSE 0 END) as denied_claims
    FROM hls_amer_catalog.r_health_gold.timely_filing_appeals
    """

    results = execute_query(query)
    return results[0] if results else {}


# ==============================================================================
# SCENARIO 5: DOCUMENTATION MANAGEMENT
# ==============================================================================

@app.get("/api/documentation-management")
def get_documentation_management(
    doc_type: Optional[str] = Query(None, description="Filter by documentation type"),
    payer: Optional[str] = Query(None, description="Filter by payer"),
    urgency: Optional[str] = Query(None, description="Filter by urgency level"),
    limit: Optional[int] = Query(100, description="Maximum results to return")
):
    """
    Get documentation management - request tracking & SLA compliance
    """
    query = """
    SELECT
        documentation_type,
        payer_name,
        drg_code,
        request_urgency,
        documentation_complexity,
        total_requests,
        completed_requests,
        avg_turnaround_days,
        associated_claims,
        associated_claim_value,
        completion_rate,
        sla_compliance_score
    FROM hls_amer_catalog.r_health_gold.documentation_management
    WHERE 1=1
    """

    if doc_type:
        query += f" AND documentation_type = '{doc_type}'"

    if payer:
        query += f" AND payer_name = '{payer}'"

    if urgency:
        query += f" AND request_urgency = '{urgency}'"

    query += f" ORDER BY associated_claim_value DESC LIMIT {limit}"

    return execute_query(query)


@app.get("/api/documentation-management/summary")
def get_documentation_summary():
    """Get summary statistics for documentation management"""
    query = """
    SELECT
        COUNT(*) as total_doc_groups,
        SUM(total_requests) as total_requests,
        SUM(completed_requests) as total_completed,
        ROUND(AVG(avg_turnaround_days), 1) as overall_avg_turnaround,
        ROUND(AVG(completion_rate), 2) as overall_completion_rate,
        ROUND(AVG(sla_compliance_score), 2) as overall_sla_compliance,
        ROUND(SUM(associated_claim_value), 2) as total_claim_value
    FROM hls_amer_catalog.r_health_gold.documentation_management
    """

    results = execute_query(query)
    return results[0] if results else {}


# ==============================================================================
# UTILITY ENDPOINTS
# ==============================================================================

@app.get("/api/payers")
def get_payers():
    """Get list of all payers across scenarios"""
    query = """
    SELECT DISTINCT payer_name
    FROM (
        SELECT payer_name FROM hls_amer_catalog.r_health_gold.denials_management
        UNION
        SELECT payer_name FROM hls_amer_catalog.r_health_gold.timely_filing_appeals
        UNION
        SELECT payer_name FROM hls_amer_catalog.r_health_gold.documentation_management
    )
    ORDER BY payer_name
    """

    return execute_query(query)


@app.get("/api/drg-codes")
def get_drg_codes():
    """Get list of all DRG codes across scenarios"""
    query = """
    SELECT DISTINCT drg_code
    FROM (
        SELECT drg_code FROM hls_amer_catalog.r_health_gold.capacity_management
        UNION
        SELECT drg_code FROM hls_amer_catalog.r_health_gold.denials_management
        UNION
        SELECT drg_code FROM hls_amer_catalog.r_health_gold.timely_filing_appeals
    )
    WHERE drg_code IS NOT NULL
    ORDER BY drg_code
    """

    return execute_query(query)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
