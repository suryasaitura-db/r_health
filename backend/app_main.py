"""
R_Health FastAPI Backend for Databricks Apps Deployment
Serves both API endpoints and React frontend static files
"""
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from databricks.sdk import WorkspaceClient
from pathlib import Path
from typing import List, Dict, Any, Optional
import os

app = FastAPI(
    title="R_Health Healthcare Analytics API",
    description="FastAPI backend for Renown Health RFP demo - 5 healthcare analytics scenarios",
    version="1.0.0"
)

# CORS middleware
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

        columns = [col.name for col in response.result.manifest.schema.columns]
        results = []
        for row in response.result.data_array:
            results.append(dict(zip(columns, row)))

        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database query error: {str(e)}")


# ==============================================================================
# API ENDPOINTS (Same as main.py - all 14 endpoints)
# ==============================================================================

@app.get("/api/health")
def health_check():
    return {"status": "healthy", "service": "R_Health API"}


@app.get("/api/info")
def api_info():
    return {
        "name": "R_Health Healthcare Analytics API",
        "version": "1.0.0",
        "scenarios": [
            "Capacity Management",
            "Denials Management",
            "Clinical Trial Matching",
            "Timely Filing & Appeals",
            "Documentation Management"
        ]
    }


# Capacity Management
@app.get("/api/capacity-management")
def get_capacity_management(
    priority: Optional[str] = None,
    min_encounters: Optional[int] = None,
    limit: Optional[int] = 100
):
    query = """
    SELECT * FROM hls_amer_catalog.r_health_gold.capacity_management
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
    query = """
    SELECT
        COUNT(*) as total_drgs,
        SUM(total_encounters) as total_encounters,
        SUM(total_bed_days) as total_bed_days,
        ROUND(AVG(avg_los), 2) as overall_avg_los,
        SUM(estimated_cost_opportunity) as total_cost_opportunity,
        SUM(CASE WHEN optimization_priority LIKE '%Critical%' THEN 1 ELSE 0 END) as critical_count,
        SUM(CASE WHEN optimization_priority LIKE '%High%' THEN 1 ELSE 0 END) as high_priority_count
    FROM hls_amer_catalog.r_health_gold.capacity_management
    """
    results = execute_query(query)
    return results[0] if results else {}


# Denials Management
@app.get("/api/denials-management")
def get_denials_management(
    payer: Optional[str] = None,
    denial_category: Optional[str] = None,
    limit: Optional[int] = 100
):
    query = "SELECT * FROM hls_amer_catalog.r_health_gold.denials_management WHERE 1=1"
    if payer:
        query += f" AND payer_name = '{payer}'"
    if denial_category:
        query += f" AND denial_category = '{denial_category}'"
    query += f" ORDER BY priority_score DESC LIMIT {limit}"
    return execute_query(query)


@app.get("/api/denials-management/summary")
def get_denials_summary():
    query = """
    SELECT
        COUNT(*) as total_denial_groups,
        SUM(total_denials) as total_denials,
        SUM(total_appealed) as total_appealed,
        ROUND(SUM(total_denied_amount), 2) as total_denied_amount,
        ROUND(SUM(recovered_amount), 2) as total_recovered,
        ROUND(AVG(appeal_win_rate), 2) as avg_win_rate
    FROM hls_amer_catalog.r_health_gold.denials_management
    """
    results = execute_query(query)
    return results[0] if results else {}


# Clinical Trial Matching
@app.get("/api/clinical-trial-matching")
def get_clinical_trial_matching(
    trial_type: Optional[str] = None,
    eligible_only: Optional[bool] = False,
    limit: Optional[int] = 100
):
    query = "SELECT * FROM hls_amer_catalog.r_health_gold.clinical_trial_matching WHERE 1=1"
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
    query += f" ORDER BY eligible_trial_count DESC LIMIT {limit}"
    return execute_query(query)


@app.get("/api/clinical-trial-matching/summary")
def get_clinical_trial_summary():
    query = """
    SELECT
        COUNT(*) as total_patients,
        SUM(CASE WHEN kras_trial_eligible THEN 1 ELSE 0 END) as kras_eligible,
        SUM(CASE WHEN copd_trial_eligible THEN 1 ELSE 0 END) as copd_eligible,
        SUM(CASE WHEN pdl1_trial_eligible THEN 1 ELSE 0 END) as pdl1_eligible
    FROM hls_amer_catalog.r_health_gold.clinical_trial_matching
    """
    results = execute_query(query)
    return results[0] if results else {}


# Timely Filing & Appeals
@app.get("/api/timely-filing-appeals")
def get_timely_filing_appeals(
    urgency: Optional[str] = None,
    compliance_status: Optional[str] = None,
    limit: Optional[int] = 100
):
    query = "SELECT * FROM hls_amer_catalog.r_health_gold.timely_filing_appeals WHERE 1=1"
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
    query += f" ORDER BY urgency_score DESC LIMIT {limit}"
    return execute_query(query)


@app.get("/api/timely-filing-appeals/summary")
def get_timely_filing_summary():
    query = """
    SELECT
        COUNT(*) as total_claims,
        SUM(CASE WHEN is_at_risk THEN 1 ELSE 0 END) as at_risk_claims,
        SUM(CASE WHEN urgency_score >= 90 THEN 1 ELSE 0 END) as critical_urgency,
        ROUND(SUM(at_risk_amount), 2) as total_at_risk_amount
    FROM hls_amer_catalog.r_health_gold.timely_filing_appeals
    """
    results = execute_query(query)
    return results[0] if results else {}


# Documentation Management
@app.get("/api/documentation-management")
def get_documentation_management(
    doc_type: Optional[str] = None,
    payer: Optional[str] = None,
    urgency: Optional[str] = None,
    limit: Optional[int] = 100
):
    query = "SELECT * FROM hls_amer_catalog.r_health_gold.documentation_management WHERE 1=1"
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
    query = """
    SELECT
        COUNT(*) as total_doc_groups,
        SUM(total_requests) as total_requests,
        SUM(completed_requests) as total_completed,
        ROUND(AVG(avg_turnaround_days), 1) as overall_avg_turnaround,
        ROUND(AVG(completion_rate), 2) as overall_completion_rate
    FROM hls_amer_catalog.r_health_gold.documentation_management
    """
    results = execute_query(query)
    return results[0] if results else {}


# Utility endpoints
@app.get("/api/payers")
def get_payers():
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
    query = """
    SELECT DISTINCT drg_code
    FROM (
        SELECT drg_code FROM hls_amer_catalog.r_health_gold.capacity_management
        UNION
        SELECT drg_code FROM hls_amer_catalog.r_health_gold.denials_management
    )
    WHERE drg_code IS NOT NULL
    ORDER BY drg_code
    """
    return execute_query(query)


# ==============================================================================
# SERVE REACT FRONTEND
# ==============================================================================

# Mount static files directory (built React app)
static_dir = Path(__file__).parent.parent / "frontend" / "dist"
if static_dir.exists():
    app.mount("/assets", StaticFiles(directory=str(static_dir / "assets")), name="assets")

    @app.get("/{full_path:path}")
    async def serve_react_app(full_path: str):
        """Serve React SPA - all non-API routes return index.html"""
        # API routes are handled above
        if full_path.startswith("api/"):
            raise HTTPException(status_code=404, detail="API endpoint not found")

        # Serve index.html for all other routes (React Router handles client-side routing)
        index_file = static_dir / "index.html"
        if index_file.exists():
            return FileResponse(index_file)
        else:
            raise HTTPException(status_code=404, detail="Frontend not built")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
