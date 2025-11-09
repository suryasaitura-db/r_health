-- ============================================================================
-- R_HEALTH GOLD LAYER - BUSINESS-READY ANALYTICAL DATASETS
-- ============================================================================
-- Purpose: Transform Silver layer into business-specific analytical datasets
--          for the 5 Renown Health RFP scenarios
-- Source: hls_amer_catalog.r_health_silver.*
-- Target: hls_amer_catalog.r_health_gold.*
-- ============================================================================

-- Create Gold schema
CREATE SCHEMA IF NOT EXISTS hls_amer_catalog.r_health_gold
COMMENT 'Gold layer - Business-ready analytical datasets for RFP scenarios';

-- ============================================================================
-- SCENARIO 1: CAPACITY MANAGEMENT
-- ============================================================================
-- Purpose: Hospital bed utilization, length of stay optimization, capacity planning
-- Key Metrics: Occupancy rates, GMLOS variance, patient flow, bottlenecks

CREATE OR REPLACE TABLE hls_amer_catalog.r_health_gold.capacity_management AS
WITH capacity_metrics AS (
  SELECT
    e.drg_code,
    e.primary_diagnosis_code,

    -- Volume metrics
    COUNT(DISTINCT e.encounter_id) AS total_encounters,
    COUNT(DISTINCT e.patient_id) AS unique_patients,

    -- Length of stay analytics
    AVG(e.length_of_stay) AS avg_los,
    e.gmlos_benchmark,
    AVG((e.gmlos_variance_percent / 100.0) * e.gmlos_benchmark) AS avg_los_variance,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY e.length_of_stay) AS median_los,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY e.length_of_stay) AS p90_los,

    -- Capacity utilization
    SUM(e.length_of_stay) AS total_bed_days,

    -- Patient complexity (higher age = higher complexity)
    AVG(p.age_years) AS avg_patient_age,

    -- Discharge patterns
    SUM(CASE WHEN e.discharge_disposition = 'Home' THEN 1 ELSE 0 END) AS discharges_home,
    SUM(CASE WHEN e.discharge_disposition = 'SNF' THEN 1 ELSE 0 END) AS discharges_snf,
    SUM(CASE WHEN e.discharge_disposition = 'Transfer' THEN 1 ELSE 0 END) AS discharges_transfer,

    -- Opportunity identification
    SUM(CASE WHEN (e.gmlos_variance_percent / 100.0) * e.gmlos_benchmark > 2 THEN 1 ELSE 0 END) AS high_variance_count,
    SUM(CASE WHEN (e.gmlos_variance_percent / 100.0) * e.gmlos_benchmark > 2 THEN (e.gmlos_variance_percent / 100.0) * e.gmlos_benchmark ELSE 0 END) AS excess_days,

    -- Financial impact (using average reimbursement per day)
    SUM(CASE WHEN (e.gmlos_variance_percent / 100.0) * e.gmlos_benchmark > 2 THEN (e.gmlos_variance_percent / 100.0) * e.gmlos_benchmark * 1500 ELSE 0 END) AS estimated_cost_opportunity

  FROM hls_amer_catalog.r_health_silver.encounters e
  LEFT JOIN hls_amer_catalog.r_health_silver.patients p
    ON e.patient_id = p.patient_id
  WHERE e.encounter_type = 'Inpatient'
  GROUP BY e.drg_code, e.primary_diagnosis_code, e.gmlos_benchmark
)
SELECT
  cm.drg_code,
  cm.primary_diagnosis_code,
  cm.total_encounters,
  cm.unique_patients,

  -- LOS Performance
  cm.avg_los,
  cm.median_los,
  cm.p90_los,
  cm.gmlos_benchmark,
  cm.avg_los_variance,
  ROUND((cm.avg_los / NULLIF(cm.gmlos_benchmark, 0) - 1) * 100, 1) AS los_variance_pct,

  -- Capacity Metrics
  cm.total_bed_days,
  cm.avg_patient_age,

  -- Discharge Mix
  ROUND(cm.discharges_home * 100.0 / NULLIF(cm.total_encounters, 0), 1) AS pct_discharge_home,
  ROUND(cm.discharges_snf * 100.0 / NULLIF(cm.total_encounters, 0), 1) AS pct_discharge_snf,
  ROUND(cm.discharges_transfer * 100.0 / NULLIF(cm.total_encounters, 0), 1) AS pct_discharge_transfer,

  -- Optimization Opportunity
  cm.high_variance_count,
  cm.excess_days,
  cm.estimated_cost_opportunity,

  -- Priority Scoring (higher score = higher priority for intervention)
  CASE
    WHEN cm.high_variance_count > 10 AND cm.avg_los_variance > 3 THEN 'Critical - Immediate Action'
    WHEN cm.high_variance_count > 5 AND cm.avg_los_variance > 2 THEN 'High Priority'
    WHEN cm.high_variance_count > 0 THEN 'Medium Priority'
    ELSE 'Low Priority'
  END AS optimization_priority,

  -- Recommendations
  CASE
    WHEN cm.discharges_snf * 100.0 / NULLIF(cm.total_encounters, 0) > 30 AND cm.avg_los_variance > 2 THEN 'Review SNF discharge criteria and care coordination'
    WHEN cm.avg_los > cm.gmlos_benchmark * 1.2 THEN 'Implement clinical pathway standardization'
    WHEN cm.high_variance_count > 5 THEN 'Conduct case review for high-variance encounters'
    ELSE 'Monitor performance trends'
  END AS recommended_action,

  CURRENT_TIMESTAMP() AS gold_load_timestamp
FROM capacity_metrics cm
WHERE cm.total_encounters >= 5  -- Minimum volume threshold for statistical significance
ORDER BY cm.estimated_cost_opportunity DESC;

SELECT 'Created Gold Capacity Management Table:', COUNT(*) AS record_count
FROM hls_amer_catalog.r_health_gold.capacity_management;

-- ============================================================================
-- SCENARIO 2: DENIALS MANAGEMENT
-- ============================================================================
-- Purpose: Claim denial tracking, appeal opportunities, denial prevention
-- Key Metrics: Denial rates, financial impact, top denial reasons, appeal success

CREATE OR REPLACE TABLE hls_amer_catalog.r_health_gold.denials_management AS
WITH denial_analytics AS (
  SELECT
    c.payer_name,
    c.payer_category,
    c.denial_reason,
    c.denial_priority,
    c.drg_code,

    -- Volume metrics
    COUNT(DISTINCT c.claim_id) AS total_denied_claims,
    COUNT(DISTINCT c.patient_id) AS unique_patients,

    -- Financial impact
    SUM(c.billed_amount) AS total_denied_amount,
    SUM(c.outstanding_balance) AS total_outstanding,
    AVG(c.billed_amount) AS avg_claim_amount,

    -- Claim characteristics
    AVG(c.claim_age_days) AS avg_claim_age,
    SUM(CASE WHEN c.has_prior_auth = TRUE THEN 1 ELSE 0 END) AS claims_with_prior_auth,

    -- Appeal opportunity
    SUM(CASE WHEN c.appeal_recommended = TRUE THEN 1 ELSE 0 END) AS appeal_opportunities,
    SUM(CASE WHEN c.appeal_recommended = TRUE THEN c.billed_amount ELSE 0 END) AS appeal_opportunity_value,

    -- Join with denials table for appeal outcomes
    SUM(CASE WHEN d.appeal_status = 'Won' THEN 1 ELSE 0 END) AS appeals_won,
    SUM(CASE WHEN d.appeal_status IN ('Lost', 'Partially Won') THEN 1 ELSE 0 END) AS appeals_lost,
    SUM(CASE WHEN d.appeal_outcome = 'Full Overturn' THEN d.billed_amount ELSE 0 END) AS recovered_amount

  FROM hls_amer_catalog.r_health_silver.claims c
  LEFT JOIN hls_amer_catalog.r_health_silver.denials d
    ON c.claim_id = d.claim_id
  WHERE c.claim_status = 'Denied'
  GROUP BY c.payer_name, c.payer_category, c.denial_reason, c.denial_priority, c.drg_code
)
SELECT
  da.payer_name,
  da.payer_category,
  da.denial_reason,
  da.denial_priority,
  da.drg_code,

  -- Denial Volume
  da.total_denied_claims,
  da.unique_patients,

  -- Financial Impact
  da.total_denied_amount,
  da.total_outstanding,
  da.avg_claim_amount,
  da.avg_claim_age,

  -- Appeal Performance
  da.appeal_opportunities,
  da.appeal_opportunity_value,
  da.appeals_won,
  da.appeals_lost,
  da.recovered_amount,

  -- Success Rates
  ROUND(da.appeals_won * 100.0 / NULLIF(da.appeals_won + da.appeals_lost, 0), 1) AS appeal_win_rate_pct,
  ROUND(da.recovered_amount * 100.0 / NULLIF(da.total_denied_amount, 0), 1) AS recovery_rate_pct,

  -- Risk Scoring
  CASE
    WHEN da.total_denied_amount > 100000 AND ROUND(da.appeals_won * 100.0 / NULLIF(da.appeals_won + da.appeals_lost, 0), 1) > 50 THEN 'High Value - High Win Rate'
    WHEN da.total_denied_amount > 50000 THEN 'High Value - Review Urgently'
    WHEN ROUND(da.appeals_won * 100.0 / NULLIF(da.appeals_won + da.appeals_lost, 0), 1) > 70 THEN 'High Win Rate - Scale Appeals'
    ELSE 'Standard Process'
  END AS denial_category,

  -- Recommended Actions
  CASE
    WHEN da.denial_reason = 'Prior Authorization Required' AND da.claims_with_prior_auth < da.total_denied_claims * 0.5
      THEN 'Implement pre-service authorization workflow'
    WHEN da.denial_reason = 'Medical Necessity' AND ROUND(da.appeals_won * 100.0 / NULLIF(da.appeals_won + da.appeals_lost, 0), 1) > 60
      THEN 'Increase appeal volume - high success rate'
    WHEN da.denial_reason = 'Coding Error'
      THEN 'Provide coder training and implement coding review'
    WHEN da.denial_reason = 'Timely Filing'
      THEN 'Review claim submission workflows and deadlines'
    ELSE 'Standard denial management process'
  END AS recommended_action,

  -- Prevention Opportunity
  ROUND(da.total_denied_amount * 0.7, 2) AS preventable_amount_estimate,  -- Assume 70% preventable

  CURRENT_TIMESTAMP() AS gold_load_timestamp
FROM denial_analytics da
WHERE da.total_denied_claims >= 3  -- Minimum volume threshold
ORDER BY da.total_denied_amount DESC;

SELECT 'Created Gold Denials Management Table:', COUNT(*) AS record_count
FROM hls_amer_catalog.r_health_gold.denials_management;

-- ============================================================================
-- SCENARIO 3: CLINICAL TRIAL MATCHING
-- ============================================================================
-- Purpose: Identify eligible patients for clinical trials
-- Key Metrics: KRAS G12C, COPD severity, PD-L1 status, trial eligibility

CREATE OR REPLACE TABLE hls_amer_catalog.r_health_gold.clinical_trial_matching AS
WITH trial_candidates AS (
  SELECT
    p.patient_id,
    p.gender,
    p.age_years,
    p.age_group,
    p.race,
    p.ethnicity,
    p.kras_mutation_status,
    p.copd_severity,
    p.eligible_kras_trial,
    p.eligible_copd_trial,
    p.patient_risk_level,

    -- Recent encounters
    COUNT(DISTINCT e.encounter_id) AS total_encounters,
    MAX(e.admission_date) AS last_encounter_date,

    -- Lab results for trial eligibility
    MAX(CASE WHEN lr.test_name = 'FEV1' THEN CAST(lr.test_result AS DOUBLE) ELSE NULL END) AS latest_fev1,
    MAX(CASE WHEN lr.test_name = 'PD-L1' THEN CAST(lr.test_result AS DOUBLE) ELSE NULL END) AS latest_pdl1,
    MAX(CASE WHEN lr.test_name = 'KRAS G12C' THEN lr.test_result ELSE NULL END) AS latest_kras_result,
    MAX(lr.lab_date) AS latest_lab_date,

    -- Clinical trial specific flags from lab results
    MAX(lr.kras_g12c_trial_eligible) AS lab_confirmed_kras_eligible,
    MAX(CASE WHEN lr.fev1_category IN ('Severe (< 30%)', 'Moderate (30-49%)') THEN TRUE ELSE FALSE END) AS lab_confirmed_copd_eligible,
    MAX(CASE WHEN lr.pdl1_expression_level = 'High Expression (>50%)' THEN TRUE ELSE FALSE END) AS lab_confirmed_pdl1_eligible

  FROM hls_amer_catalog.r_health_silver.patients p
  LEFT JOIN hls_amer_catalog.r_health_silver.encounters e
    ON p.patient_id = e.patient_id
  LEFT JOIN hls_amer_catalog.r_health_silver.lab_results lr
    ON p.patient_id = lr.patient_id
  GROUP BY p.patient_id, p.gender, p.age_years, p.age_group, p.race, p.ethnicity,
           p.kras_mutation_status, p.copd_severity, p.eligible_kras_trial,
           p.eligible_copd_trial, p.patient_risk_level
)
SELECT
  tc.patient_id,
  tc.age_years,
  tc.age_group,
  tc.gender,
  tc.race,
  tc.ethnicity,

  -- Clinical Characteristics
  tc.kras_mutation_status,
  tc.copd_severity,
  tc.latest_fev1,
  tc.latest_pdl1,
  tc.latest_kras_result,
  tc.latest_lab_date,
  tc.patient_risk_level,

  -- Trial Eligibility
  tc.eligible_kras_trial,
  tc.eligible_copd_trial,
  tc.lab_confirmed_kras_eligible,
  tc.lab_confirmed_copd_eligible,
  tc.lab_confirmed_pdl1_eligible,

  -- Specific Trial Recommendations
  CASE
    WHEN tc.kras_mutation_status = 'KRAS G12C Positive' AND tc.lab_confirmed_kras_eligible = TRUE
      THEN 'KRAS G12C Inhibitor Trial - Confirmed Eligible'
    WHEN tc.kras_mutation_status = 'KRAS G12C Positive'
      THEN 'KRAS G12C Trial - Requires Confirmatory Testing'
    ELSE 'Not Eligible for KRAS Trial'
  END AS kras_trial_status,

  CASE
    WHEN tc.copd_severity IN ('Severe COPD (FEV1 < 30%)', 'Moderate COPD (FEV1 30-49%)')
         AND tc.latest_fev1 IS NOT NULL AND tc.latest_fev1 < 50
      THEN 'COPD Treatment Trial - Confirmed Eligible'
    WHEN tc.copd_severity IN ('Severe COPD (FEV1 < 30%)', 'Moderate COPD (FEV1 30-49%)')
      THEN 'COPD Trial - Requires FEV1 Confirmation'
    ELSE 'Not Eligible for COPD Trial'
  END AS copd_trial_status,

  CASE
    WHEN tc.latest_pdl1 >= 50 THEN 'Immunotherapy Trial - High PD-L1 (≥50%)'
    WHEN tc.latest_pdl1 BETWEEN 1 AND 49 THEN 'Immunotherapy Trial - Low PD-L1 (1-49%)'
    WHEN tc.latest_pdl1 = 0 THEN 'Not Eligible - PD-L1 Negative'
    ELSE 'PD-L1 Testing Needed'
  END AS pdl1_trial_status,

  -- Engagement Metrics
  tc.total_encounters,
  tc.last_encounter_date,
  DATEDIFF(DAY, tc.last_encounter_date, CURRENT_DATE()) AS days_since_last_visit,

  -- Priority Scoring
  CASE
    WHEN tc.lab_confirmed_kras_eligible = TRUE AND DATEDIFF(DAY, tc.last_encounter_date, CURRENT_DATE()) < 90
      THEN 'Immediate Contact - KRAS Trial Ready'
    WHEN tc.lab_confirmed_copd_eligible = TRUE AND tc.latest_fev1 < 30
      THEN 'Urgent Contact - Severe COPD Trial'
    WHEN tc.latest_pdl1 >= 50 AND DATEDIFF(DAY, tc.last_encounter_date, CURRENT_DATE()) < 180
      THEN 'Priority Contact - High PD-L1'
    WHEN (tc.eligible_kras_trial = TRUE OR tc.eligible_copd_trial = TRUE)
      THEN 'Follow-up Needed - Confirm Eligibility'
    ELSE 'Monitor'
  END AS outreach_priority,

  -- Next Steps
  CASE
    WHEN tc.lab_confirmed_kras_eligible = TRUE THEN 'Schedule trial screening visit'
    WHEN tc.kras_mutation_status = 'KRAS G12C Positive' AND tc.latest_kras_result IS NULL
      THEN 'Order confirmatory KRAS testing'
    WHEN tc.copd_severity LIKE '%COPD%' AND tc.latest_fev1 IS NULL
      THEN 'Order FEV1 testing'
    WHEN tc.kras_mutation_status LIKE 'KRAS%' AND tc.latest_pdl1 IS NULL
      THEN 'Order PD-L1 testing'
    ELSE 'Continue standard monitoring'
  END AS recommended_next_step,

  CURRENT_TIMESTAMP() AS gold_load_timestamp
FROM trial_candidates tc
WHERE
  tc.eligible_kras_trial = TRUE
  OR tc.eligible_copd_trial = TRUE
  OR tc.latest_pdl1 >= 1
  OR tc.kras_mutation_status LIKE 'KRAS%'
ORDER BY
  CASE
    WHEN tc.lab_confirmed_kras_eligible = TRUE THEN 1
    WHEN tc.lab_confirmed_copd_eligible = TRUE THEN 2
    WHEN tc.latest_pdl1 >= 50 THEN 3
    ELSE 4
  END,
  tc.last_encounter_date DESC;

SELECT 'Created Gold Clinical Trial Matching Table:', COUNT(*) AS record_count
FROM hls_amer_catalog.r_health_gold.clinical_trial_matching;

-- ============================================================================
-- SCENARIO 4: TIMELY FILING & APPEALS
-- ============================================================================
-- Purpose: Compliance tracking, deadline management, appeal prioritization
-- Key Metrics: Filing deadlines, compliance status, urgency, financial risk

CREATE OR REPLACE TABLE hls_amer_catalog.r_health_gold.timely_filing_appeals AS
WITH filing_status AS (
  SELECT
    tf.claim_id,
    tf.patient_id,
    tf.payer_name,
    tf.service_date,
    tf.filing_deadline,
    tf.days_to_deadline,
    tf.compliance_status,
    tf.filing_urgency,

    -- Claim details from claims table
    c.billed_amount,
    c.outstanding_balance,
    c.claim_status,
    c.denial_reason,
    c.denial_priority,
    c.appeal_recommended,

    -- Denial details if exists
    d.denial_id,
    d.denial_date,
    d.appeal_status,
    d.appeal_outcome,

    -- Calculate financial risk
    CASE
      WHEN tf.days_to_deadline < 30 AND c.billed_amount > 5000 THEN c.billed_amount
      WHEN tf.days_to_deadline < 60 AND c.billed_amount > 10000 THEN c.billed_amount * 0.5
      ELSE 0
    END AS financial_risk_amount

  FROM hls_amer_catalog.r_health_silver.timely_filing tf
  INNER JOIN hls_amer_catalog.r_health_silver.claims c
    ON tf.claim_id = c.claim_id
  LEFT JOIN hls_amer_catalog.r_health_silver.denials d
    ON c.claim_id = d.claim_id
  WHERE tf.compliance_status != 'Compliant - Safe'  -- Focus on at-risk claims
)
SELECT
  fs.claim_id,
  fs.patient_id,
  fs.payer_name,
  fs.service_date,
  fs.filing_deadline,
  fs.days_to_deadline,
  fs.compliance_status,
  fs.filing_urgency,

  -- Financial Metrics
  fs.billed_amount,
  fs.outstanding_balance,
  fs.financial_risk_amount,

  -- Claim Status
  fs.claim_status,
  fs.denial_reason,
  fs.denial_priority,
  fs.appeal_recommended,

  -- Appeal Tracking
  fs.denial_id,
  fs.denial_date,
  fs.appeal_status,
  fs.appeal_outcome,

  -- Combined Urgency Score (1-10 scale)
  CASE
    WHEN fs.days_to_deadline < 7 AND fs.billed_amount > 10000 THEN 10
    WHEN fs.days_to_deadline < 14 AND fs.billed_amount > 5000 THEN 9
    WHEN fs.days_to_deadline < 30 AND fs.billed_amount > 10000 THEN 8
    WHEN fs.days_to_deadline < 30 AND fs.billed_amount > 5000 THEN 7
    WHEN fs.days_to_deadline < 60 AND fs.billed_amount > 10000 THEN 6
    WHEN fs.days_to_deadline < 60 THEN 5
    WHEN fs.days_to_deadline < 90 AND fs.billed_amount > 10000 THEN 4
    WHEN fs.days_to_deadline < 90 THEN 3
    WHEN fs.days_to_deadline < 120 THEN 2
    ELSE 1
  END AS urgency_score,

  -- Action Required
  CASE
    WHEN fs.days_to_deadline < 0 THEN 'OVERDUE - File Immediately or Write Off'
    WHEN fs.days_to_deadline <= 7 THEN 'CRITICAL - File This Week'
    WHEN fs.days_to_deadline <= 14 THEN 'URGENT - File Within 2 Weeks'
    WHEN fs.days_to_deadline <= 30 THEN 'High Priority - File This Month'
    WHEN fs.days_to_deadline <= 60 THEN 'Medium Priority - Track Closely'
    ELSE 'Low Priority - Monitor'
  END AS action_required,

  -- Recommended Owner
  CASE
    WHEN fs.denial_reason = 'Medical Necessity' THEN 'Clinical Appeals Team'
    WHEN fs.denial_reason IN ('Prior Authorization Required', 'Out of Network') THEN 'Authorization Team'
    WHEN fs.denial_reason IN ('Coding Error', 'Duplicate Claim') THEN 'Billing Department'
    WHEN fs.billed_amount > 25000 THEN 'Senior Revenue Cycle Analyst'
    ELSE 'Standard Filing Queue'
  END AS assigned_team,

  -- Workflow Status
  CASE
    WHEN fs.appeal_status IS NOT NULL THEN 'In Appeal Process'
    WHEN fs.claim_status = 'Denied' AND fs.appeal_recommended = TRUE THEN 'Appeal Recommended'
    WHEN fs.claim_status = 'Pending' AND fs.days_to_deadline < 30 THEN 'Pending - Urgent Follow-up'
    WHEN fs.claim_status = 'Pending' THEN 'Pending - Monitor'
    ELSE 'Standard Processing'
  END AS workflow_status,

  CURRENT_TIMESTAMP() AS gold_load_timestamp
FROM filing_status fs
ORDER BY
  urgency_score DESC,
  financial_risk_amount DESC,
  days_to_deadline ASC;

SELECT 'Created Gold Timely Filing & Appeals Table:', COUNT(*) AS record_count
FROM hls_amer_catalog.r_health_gold.timely_filing_appeals;

-- ============================================================================
-- SCENARIO 5: DOCUMENTATION MANAGEMENT
-- ============================================================================
-- Purpose: Track documentation requests, completion rates, turnaround times
-- Key Metrics: Request volume, completion status, TAT, complexity, bottlenecks

CREATE OR REPLACE TABLE hls_amer_catalog.r_health_gold.documentation_management AS
WITH doc_analytics AS (
  SELECT
    dr.documentation_type,
    dr.payer_name,
    dr.drg_code,
    dr.request_urgency,
    dr.documentation_complexity,

    -- Volume metrics
    COUNT(DISTINCT dr.request_id) AS total_requests,
    COUNT(DISTINCT dr.patient_id) AS unique_patients,

    -- Status breakdown
    SUM(CASE WHEN dr.response_status = 'Completed' THEN 1 ELSE 0 END) AS completed_requests,
    SUM(CASE WHEN dr.response_status = 'Pending' THEN 1 ELSE 0 END) AS pending_requests,
    SUM(CASE WHEN dr.response_status = 'In Progress' THEN 1 ELSE 0 END) AS in_progress_requests,

    -- Turnaround time analysis
    AVG(dr.days_to_respond) AS avg_turnaround_days,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dr.days_to_respond) AS median_turnaround_days,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY dr.days_to_respond) AS p90_turnaround_days,
    MAX(dr.days_to_respond) AS max_turnaround_days,

    -- SLA compliance (assume 10 days for standard, 5 for urgent)
    SUM(CASE
      WHEN dr.request_urgency LIKE 'HIGH%' AND dr.days_to_respond <= 5 THEN 1
      WHEN dr.request_urgency NOT LIKE 'HIGH%' AND dr.days_to_respond <= 10 THEN 1
      WHEN dr.response_status IN ('Pending', 'In Progress') THEN 0  -- Don't count pending in SLA
      ELSE 0
    END) AS sla_met_count,

    -- Age of pending requests
    AVG(CASE WHEN dr.response_status IN ('Pending', 'In Progress')
        THEN dr.request_age_days ELSE NULL END) AS avg_pending_age_days,

    -- Associated claims (join on claim_id directly)
    COUNT(DISTINCT c.claim_id) AS associated_claims,
    SUM(c.billed_amount) AS associated_claim_value

  FROM hls_amer_catalog.r_health_silver.documentation_requests dr
  LEFT JOIN hls_amer_catalog.r_health_silver.claims c
    ON dr.claim_id = c.claim_id
  GROUP BY dr.documentation_type, dr.payer_name, dr.drg_code,
           dr.request_urgency, dr.documentation_complexity
)
SELECT
  da.documentation_type,
  da.payer_name,
  da.drg_code,
  da.request_urgency,
  da.documentation_complexity,

  -- Volume Metrics
  da.total_requests,
  da.unique_patients,

  -- Status Distribution
  da.completed_requests,
  da.pending_requests,
  da.in_progress_requests,
  ROUND(da.completed_requests * 100.0 / NULLIF(da.total_requests, 0), 1) AS completion_rate_pct,

  -- Turnaround Time Performance
  da.avg_turnaround_days,
  da.median_turnaround_days,
  da.p90_turnaround_days,
  da.max_turnaround_days,

  -- SLA Performance
  da.sla_met_count,
  ROUND(da.sla_met_count * 100.0 / NULLIF(da.completed_requests, 0), 1) AS sla_compliance_rate_pct,

  -- Workload
  da.avg_pending_age_days,

  -- Financial Impact
  da.associated_claims,
  da.associated_claim_value,
  ROUND(da.associated_claim_value / NULLIF(da.total_requests, 0), 2) AS avg_claim_value_per_request,

  -- Performance Category
  CASE
    WHEN ROUND(da.sla_met_count * 100.0 / NULLIF(da.completed_requests, 0), 1) >= 95 THEN 'Excellent Performance'
    WHEN ROUND(da.sla_met_count * 100.0 / NULLIF(da.completed_requests, 0), 1) >= 85 THEN 'Good Performance'
    WHEN ROUND(da.sla_met_count * 100.0 / NULLIF(da.completed_requests, 0), 1) >= 75 THEN 'Needs Improvement'
    ELSE 'Critical - Action Required'
  END AS performance_category,

  -- Bottleneck Identification
  CASE
    WHEN da.avg_pending_age_days > 15 AND da.pending_requests > 10
      THEN 'Critical Backlog - Add Resources'
    WHEN da.p90_turnaround_days > 15
      THEN 'Process Inefficiency - Review Workflow'
    WHEN da.documentation_complexity = 'High Complexity' AND da.avg_turnaround_days > 10
      THEN 'High Complexity - Consider Specialist Team'
    WHEN da.pending_requests > 20
      THEN 'High Volume - Monitor Capacity'
    ELSE 'Normal Operations'
  END AS bottleneck_indicator,

  -- Recommended Actions
  CASE
    WHEN da.payer_name IN ('Medicare', 'Medicaid') AND ROUND(da.sla_met_count * 100.0 / NULLIF(da.completed_requests, 0), 1) < 80
      THEN 'Escalate - Payer SLA at risk, may impact reimbursement'
    WHEN da.request_urgency LIKE 'HIGH%' AND da.avg_pending_age_days > 5
      THEN 'Immediate triage of urgent pending requests required'
    WHEN da.documentation_complexity = 'High Complexity' AND da.avg_turnaround_days > da.median_turnaround_days * 1.5
      THEN 'Create specialized team for complex documentation'
    WHEN da.total_requests > 50 AND ROUND(da.completed_requests * 100.0 / NULLIF(da.total_requests, 0), 1) < 70
      THEN 'Process improvement initiative - high volume, low completion'
    ELSE 'Continue standard monitoring'
  END AS recommended_action,

  -- Staffing Estimate (rough estimate: 5 requests per day per FTE)
  CEILING(da.pending_requests / 5.0) AS estimated_ftes_needed_to_clear_backlog,

  CURRENT_TIMESTAMP() AS gold_load_timestamp
FROM doc_analytics da
WHERE da.total_requests >= 3  -- Minimum volume threshold
ORDER BY
  CASE
    WHEN da.request_urgency LIKE 'CRITICAL%' THEN 1
    WHEN da.request_urgency LIKE 'HIGH%' THEN 2
    ELSE 3
  END,
  da.associated_claim_value DESC,
  da.pending_requests DESC;

SELECT 'Created Gold Documentation Management Table:', COUNT(*) AS record_count
FROM hls_amer_catalog.r_health_gold.documentation_management;

-- ============================================================================
-- GOLD LAYER SUMMARY
-- ============================================================================
SELECT 'GOLD LAYER DATA TRANSFORMATION COMPLETE' AS status;

SELECT
  'Gold Layer Summary' AS summary_type,
  (SELECT COUNT(*) FROM hls_amer_catalog.r_health_gold.capacity_management) AS capacity_management_records,
  (SELECT COUNT(*) FROM hls_amer_catalog.r_health_gold.denials_management) AS denials_management_records,
  (SELECT COUNT(*) FROM hls_amer_catalog.r_health_gold.clinical_trial_matching) AS clinical_trial_matching_records,
  (SELECT COUNT(*) FROM hls_amer_catalog.r_health_gold.timely_filing_appeals) AS timely_filing_appeals_records,
  (SELECT COUNT(*) FROM hls_amer_catalog.r_health_gold.documentation_management) AS documentation_management_records,
  CURRENT_TIMESTAMP() AS summary_timestamp;
