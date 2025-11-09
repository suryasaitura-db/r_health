"""
R_Health FastAPI Backend - Simplified Version for Databricks Apps
Serves React frontend and returns sample data (no database dependency for startup)
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pathlib import Path
from typing import List, Dict, Any, Optional

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

# Sample data for testing
SAMPLE_CAPACITY_DATA = [
    {
        "drg_code": "470",
        "drg_description": "Major Joint Replacement",
        "total_encounters": 1250,
        "total_bed_days": 3750,
        "avg_los": 3.0,
        "estimated_cost_opportunity": 125000,
        "optimization_priority": "Critical - High Volume"
    },
    {
        "drg_code": "871",
        "drg_description": "Septicemia",
        "total_encounters": 980,
        "total_bed_days": 5880,
        "avg_los": 6.0,
        "estimated_cost_opportunity": 245000,
        "optimization_priority": "High - Extended LOS"
    }
]

SAMPLE_DENIALS_DATA = [
    {
        "payer_name": "Medicare",
        "denial_category": "Medical Necessity",
        "total_denials": 145,
        "total_appealed": 98,
        "total_denied_amount": 582000,
        "recovered_amount": 349200,
        "appeal_win_rate": 0.60,
        "priority_score": 95
    }
]

# ==============================================================================
# API ENDPOINTS
# ==============================================================================

@app.get("/api/health")
def health_check():
    return {"status": "healthy", "service": "R_Health API", "mode": "demo"}


@app.get("/api/info")
def api_info():
    return {
        "name": "R_Health Healthcare Analytics API",
        "version": "1.0.0",
        "mode": "Demo Mode - Sample Data",
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
    return SAMPLE_CAPACITY_DATA


@app.get("/api/capacity-management/summary")
def get_capacity_summary():
    return {
        "total_drgs": 2,
        "total_encounters": 2230,
        "total_bed_days": 9630,
        "overall_avg_los": 4.5,
        "total_cost_opportunity": 370000,
        "critical_count": 1,
        "high_priority_count": 1
    }


# Denials Management
@app.get("/api/denials-management")
def get_denials_management(
    payer: Optional[str] = None,
    denial_category: Optional[str] = None,
    limit: Optional[int] = 100
):
    return SAMPLE_DENIALS_DATA


@app.get("/api/denials-management/summary")
def get_denials_summary():
    return {
        "total_denial_groups": 1,
        "total_denials": 145,
        "total_appealed": 98,
        "total_denied_amount": 582000,
        "total_recovered": 349200,
        "avg_win_rate": 0.60
    }


# Clinical Trial Matching
@app.get("/api/clinical-trial-matching")
def get_clinical_trial_matching(
    trial_type: Optional[str] = None,
    eligible_only: Optional[bool] = False,
    limit: Optional[int] = 100
):
    return [
        {
            "patient_id": "P001",
            "eligible_trial_count": 3,
            "kras_trial_eligible": True,
            "copd_trial_eligible": False,
            "pdl1_trial_eligible": True
        }
    ]


@app.get("/api/clinical-trial-matching/summary")
def get_clinical_trial_summary():
    return {
        "total_patients": 1,
        "kras_eligible": 1,
        "copd_eligible": 0,
        "pdl1_eligible": 1
    }


# Timely Filing & Appeals
@app.get("/api/timely-filing-appeals")
def get_timely_filing_appeals(
    urgency: Optional[str] = None,
    compliance_status: Optional[str] = None,
    limit: Optional[int] = 100
):
    return [
        {
            "claim_id": "CLM001",
            "payer_name": "Aetna",
            "urgency_score": 95,
            "compliance_status": "At Risk",
            "is_at_risk": True,
            "at_risk_amount": 15000
        }
    ]


@app.get("/api/timely-filing-appeals/summary")
def get_timely_filing_summary():
    return {
        "total_claims": 1,
        "at_risk_claims": 1,
        "critical_urgency": 1,
        "total_at_risk_amount": 15000
    }


# Documentation Management
@app.get("/api/documentation-management")
def get_documentation_management(
    doc_type: Optional[str] = None,
    payer: Optional[str] = None,
    urgency: Optional[str] = None,
    limit: Optional[int] = 100
):
    return [
        {
            "documentation_type": "Medical Records",
            "payer_name": "Blue Cross",
            "total_requests": 45,
            "completed_requests": 38,
            "avg_turnaround_days": 4.2,
            "completion_rate": 0.84,
            "associated_claim_value": 125000,
            "request_urgency": "High"
        }
    ]


@app.get("/api/documentation-management/summary")
def get_documentation_summary():
    return {
        "total_doc_groups": 1,
        "total_requests": 45,
        "total_completed": 38,
        "overall_avg_turnaround": 4.2,
        "overall_completion_rate": 0.84
    }


# Utility endpoints
@app.get("/api/payers")
def get_payers():
    return [
        {"payer_name": "Medicare"},
        {"payer_name": "Aetna"},
        {"payer_name": "Blue Cross"}
    ]


@app.get("/api/drg-codes")
def get_drg_codes():
    return [
        {"drg_code": "470"},
        {"drg_code": "871"}
    ]


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
