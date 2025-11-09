-- ============================================================================
-- R_HEALTH SILVER LAYER - DATA CLEANSING, ENRICHMENT & BUSINESS RULES
-- ============================================================================
-- Purpose: Transform Bronze layer synthetic data into cleansed, enriched
--          datasets ready for Gold layer business analytics
-- Source: hls_amer_catalog.r_health_bronze.*
-- Target: hls_amer_catalog.r_health_silver.*
-- ============================================================================

-- Create Silver schema
CREATE SCHEMA IF NOT EXISTS hls_amer_catalog.r_health_silver
COMMENT 'Silver layer - Cleansed and enriched healthcare data';

-- ============================================================================
-- 1. SILVER PATIENTS - Enriched Master Patient Index
-- ============================================================================
CREATE OR REPLACE TABLE hls_amer_catalog.r_health_silver.patients AS
SELECT
  patient_id,
  gender,
  date_of_birth,
  race,
  ethnicity,

  -- Calculate age from date_of_birth
  CAST(DATEDIFF(DAY, CAST(date_of_birth AS DATE), CURRENT_DATE()) / 365.25 AS INT) AS age_years,

  -- Age group categorization
  CASE
    WHEN CAST(DATEDIFF(DAY, CAST(date_of_birth AS DATE), CURRENT_DATE()) / 365.25 AS INT) < 18 THEN 'Pediatric (< 18)'
    WHEN CAST(DATEDIFF(DAY, CAST(date_of_birth AS DATE), CURRENT_DATE()) / 365.25 AS INT) BETWEEN 18 AND 39 THEN 'Young Adult (18-39)'
    WHEN CAST(DATEDIFF(DAY, CAST(date_of_birth AS DATE), CURRENT_DATE()) / 365.25 AS INT) BETWEEN 40 AND 64 THEN 'Middle Age (40-64)'
    ELSE 'Senior (65+)'
  END AS age_group,

  kras_mutation_status,
  copd_severity,

  -- Clinical trial eligibility flags
  CASE
    WHEN kras_mutation_status = 'KRAS G12C Positive' THEN TRUE
    ELSE FALSE
  END AS eligible_kras_trial,

  CASE
    WHEN copd_severity IN ('Severe COPD (FEV1 < 30%)', 'Moderate COPD (FEV1 30-49%)') THEN TRUE
    ELSE FALSE
  END AS eligible_copd_trial,

  -- Risk stratification
  CASE
    WHEN copd_severity = 'Severe COPD (FEV1 < 30%)' THEN 'High Risk'
    WHEN copd_severity = 'Moderate COPD (FEV1 30-49%)' THEN 'Medium Risk'
    WHEN kras_mutation_status LIKE 'KRAS%Positive' THEN 'Medium Risk'
    ELSE 'Low Risk'
  END AS patient_risk_level,

  -- Data quality flags
  CASE
    WHEN patient_id IS NULL THEN 'CRITICAL'
    WHEN gender IS NULL OR kras_mutation_status IS NULL THEN 'WARNING'
    ELSE 'VALID'
  END AS data_quality_status,

  created_at,
  source_system,
  CURRENT_TIMESTAMP() AS silver_load_timestamp
FROM hls_amer_catalog.r_health_bronze.patients
WHERE patient_id IS NOT NULL;  -- Data quality filter

SELECT 'Created Silver Patients Table:', COUNT(*) AS record_count
FROM hls_amer_catalog.r_health_silver.patients;

-- ============================================================================
-- 2. SILVER ENCOUNTERS - Enriched Encounter Data with GMLOS Benchmarks
-- ============================================================================
CREATE OR REPLACE TABLE hls_amer_catalog.r_health_silver.encounters AS
WITH drg_benchmarks AS (
  -- Calculate GMLOS benchmarks per DRG code
  SELECT
    drg_code,
    EXP(AVG(LN(CASE WHEN length_of_stay > 0 THEN length_of_stay ELSE 1 END))) AS gmlos_benchmark,
    COUNT(*) AS drg_volume
  FROM hls_amer_catalog.r_health_bronze.encounters
  WHERE length_of_stay > 0
  GROUP BY drg_code
)
SELECT
  e.encounter_id,
  e.patient_id,
  e.admission_date,

  -- Add discharge date
  DATE_ADD(e.admission_date, CAST(e.length_of_stay AS INT)) AS discharge_date,

  e.encounter_type,
  e.drg_code,
  e.length_of_stay,
  e.primary_diagnosis_code,
  e.discharge_disposition,

  -- Join GMLOS benchmark
  b.gmlos_benchmark,

  -- Calculate variance from GMLOS
  CASE
    WHEN b.gmlos_benchmark > 0 THEN
      ROUND((e.length_of_stay - b.gmlos_benchmark) / b.gmlos_benchmark * 100, 2)
    ELSE 0
  END AS gmlos_variance_percent,

  -- Readmission risk indicator
  CASE
    WHEN e.discharge_disposition = 'Home (High Risk)' THEN 'High Risk'
    WHEN e.discharge_disposition = 'Skilled Nursing Facility' THEN 'Medium Risk'
    ELSE 'Low Risk'
  END AS readmission_risk,

  -- Length of stay category
  CASE
    WHEN e.length_of_stay <= 1 THEN 'Same Day / 1 Day'
    WHEN e.length_of_stay <= 3 THEN '2-3 Days'
    WHEN e.length_of_stay <= 7 THEN '4-7 Days'
    WHEN e.length_of_stay <= 14 THEN '8-14 Days'
    ELSE '15+ Days'
  END AS los_category,

  -- Capacity management flag
  CASE
    WHEN e.encounter_type = 'Inpatient' AND e.length_of_stay > b.gmlos_benchmark * 1.2 THEN TRUE
    ELSE FALSE
  END AS exceeds_gmlos_threshold,

  -- Data quality
  CASE
    WHEN e.encounter_id IS NULL OR e.patient_id IS NULL THEN 'CRITICAL'
    WHEN e.length_of_stay IS NULL OR e.length_of_stay < 0 THEN 'WARNING'
    ELSE 'VALID'
  END AS data_quality_status,

  e.created_at,
  CURRENT_TIMESTAMP() AS silver_load_timestamp
FROM hls_amer_catalog.r_health_bronze.encounters e
LEFT JOIN drg_benchmarks b ON e.drg_code = b.drg_code
WHERE e.encounter_id IS NOT NULL;

SELECT 'Created Silver Encounters Table:', COUNT(*) AS record_count
FROM hls_amer_catalog.r_health_silver.encounters;

-- ============================================================================
-- 3. SILVER CLAIMS - Enriched Claims with Financial Metrics
-- ============================================================================
CREATE OR REPLACE TABLE hls_amer_catalog.r_health_silver.claims AS
WITH claim_metrics AS (
  SELECT
    claim_id,
    encounter_id,
    patient_id,
    service_date,
    submission_date,
    payer_name,
    billed_amount,
    allowed_amount,
    patient_responsibility,
    paid_amount,
    claim_status,
    denial_reason,
    has_prior_auth,
    drg_code,
    primary_diagnosis_code,

    -- Financial calculations
    billed_amount - paid_amount AS outstanding_balance,
    CASE
      WHEN billed_amount > 0 THEN
        ROUND((paid_amount / billed_amount) * 100, 2)
      ELSE 0
    END AS payment_rate_percent,

    -- Claim age in days
    DATEDIFF(DAY, service_date, CURRENT_DATE()) AS claim_age_days,

    created_at
  FROM hls_amer_catalog.r_health_bronze.claims
)
SELECT
  cm.claim_id,
  cm.encounter_id,
  cm.patient_id,
  cm.service_date,
  cm.submission_date,
  cm.payer_name,
  cm.billed_amount,
  cm.allowed_amount,
  cm.patient_responsibility,
  cm.paid_amount,
  cm.claim_status,
  cm.denial_reason,
  cm.has_prior_auth,
  cm.drg_code,
  cm.primary_diagnosis_code,
  cm.outstanding_balance,
  cm.payment_rate_percent,
  cm.claim_age_days,
  cm.created_at,

  -- Denial risk categorization
  CASE
    WHEN cm.denial_reason = 'Prior Authorization Required' THEN 'High Priority - Pre-Auth'
    WHEN cm.denial_reason = 'Medical Necessity' THEN 'High Priority - Clinical Review'
    WHEN cm.denial_reason IN ('Coding Error', 'Duplicate Claim') THEN 'Medium Priority - Administrative'
    WHEN cm.claim_status = 'Denied' THEN 'Medium Priority - General'
    ELSE 'Low Priority'
  END AS denial_priority,

  -- Payer mix category
  CASE
    WHEN cm.payer_name = 'Medicare' THEN 'Government'
    WHEN cm.payer_name = 'Medicaid' THEN 'Government'
    ELSE 'Commercial'
  END AS payer_category,

  -- Claim status category
  CASE
    WHEN cm.claim_status = 'Paid' THEN 'Closed - Paid'
    WHEN cm.claim_status = 'Denied' THEN 'Closed - Denied'
    WHEN cm.claim_status = 'Pending' AND cm.claim_age_days > 30 THEN 'Open - Aged'
    WHEN cm.claim_status = 'Pending' THEN 'Open - Current'
    ELSE 'Unknown'
  END AS claim_category,

  -- Appeal opportunity flag
  CASE
    WHEN cm.claim_status = 'Denied'
      AND cm.denial_reason IN ('Prior Authorization Required', 'Medical Necessity', 'Out of Network')
      AND cm.billed_amount > 1000 THEN TRUE
    ELSE FALSE
  END AS appeal_recommended,

  -- Data quality
  CASE
    WHEN cm.claim_id IS NULL THEN 'CRITICAL'
    WHEN cm.billed_amount IS NULL OR cm.billed_amount < 0 THEN 'WARNING'
    WHEN cm.service_date IS NULL THEN 'WARNING'
    ELSE 'VALID'
  END AS data_quality_status,

  CURRENT_TIMESTAMP() AS silver_load_timestamp
FROM claim_metrics cm
WHERE cm.claim_id IS NOT NULL;

SELECT 'Created Silver Claims Table:', COUNT(*) AS record_count
FROM hls_amer_catalog.r_health_silver.claims;

-- ============================================================================
-- 4. SILVER DENIALS - Enriched Denial Tracking with Appeal Analytics
-- ============================================================================
CREATE OR REPLACE TABLE hls_amer_catalog.r_health_silver.denials AS
SELECT
  d.denial_id,
  d.claim_id,
  d.patient_id,
  d.service_date,
  d.submission_date,
  d.denial_date,
  d.payer_name,
  d.billed_amount,
  d.denial_reason,
  d.appeal_status,
  d.appeal_outcome,
  d.drg_code,
  d.primary_diagnosis_code,

  -- Denial aging
  DATEDIFF(DAY, d.denial_date, CURRENT_DATE()) AS denial_age_days,

  -- Appeal success rate indicator
  CASE
    WHEN d.appeal_outcome = 'Overturned - Paid in Full' THEN 100
    WHEN d.appeal_outcome = 'Partially Overturned' THEN 50
    WHEN d.appeal_outcome = 'Upheld - Remained Denied' THEN 0
    ELSE NULL
  END AS appeal_success_percent,

  -- Priority scoring
  CASE
    WHEN d.appeal_status = 'Pending Review' AND DATEDIFF(DAY, d.denial_date, CURRENT_DATE()) > 90 THEN 'Critical - Expiring Soon'
    WHEN d.appeal_status = 'Not Appealed' AND d.denial_reason IN ('Medical Necessity Not Met', 'Lack of Prior Authorization') THEN 'High - Appeal Opportunity'
    WHEN d.appeal_status = 'Pending Review' THEN 'Medium - In Progress'
    ELSE 'Low'
  END AS denial_priority,

  -- Denial prevention category
  CASE
    WHEN d.denial_reason LIKE '%Prior Authorization%' OR d.denial_reason LIKE '%Lack of Prior%' THEN 'Preventable - Pre-Auth'
    WHEN d.denial_reason LIKE '%Coding%' OR d.denial_reason LIKE '%Incorrect Coding%' THEN 'Preventable - Coding'
    WHEN d.denial_reason LIKE '%Documentation%' OR d.denial_reason LIKE '%Insufficient Documentation%' THEN 'Preventable - Documentation'
    ELSE 'Clinical Review Required'
  END AS prevention_category,

  -- Appeal filed flag
  CASE
    WHEN d.appeal_status = 'Appealed' THEN TRUE
    ELSE FALSE
  END AS appeal_filed,

  -- Data quality
  CASE
    WHEN d.denial_id IS NULL OR d.claim_id IS NULL THEN 'CRITICAL'
    WHEN d.denial_date IS NULL THEN 'WARNING'
    ELSE 'VALID'
  END AS data_quality_status,

  d.created_at,
  CURRENT_TIMESTAMP() AS silver_load_timestamp
FROM hls_amer_catalog.r_health_bronze.denials d
WHERE d.denial_id IS NOT NULL;

SELECT 'Created Silver Denials Table:', COUNT(*) AS record_count
FROM hls_amer_catalog.r_health_silver.denials;

-- ============================================================================
-- 5. SILVER LAB RESULTS - Enriched Clinical Lab Data with Trial Matching
-- ============================================================================
CREATE OR REPLACE TABLE hls_amer_catalog.r_health_silver.lab_results AS
SELECT
  lr.lab_id,
  lr.encounter_id,
  lr.patient_id,
  lr.lab_date,
  lr.test_name,
  lr.test_result,
  lr.result_unit,

  -- Extract numeric value from test_result for FEV1
  CASE
    WHEN lr.test_name = 'FEV1' AND lr.result_unit = '%' THEN CAST(lr.test_result AS DOUBLE)
    ELSE NULL
  END AS fev1_numeric_value,

  -- FEV1 stratification for COPD trials
  CASE
    WHEN lr.test_name = 'FEV1' AND CAST(lr.test_result AS DOUBLE) < 30 THEN 'Severe (< 30%)'
    WHEN lr.test_name = 'FEV1' AND CAST(lr.test_result AS DOUBLE) BETWEEN 30 AND 49 THEN 'Moderate (30-49%)'
    WHEN lr.test_name = 'FEV1' AND CAST(lr.test_result AS DOUBLE) BETWEEN 50 AND 79 THEN 'Mild (50-79%)'
    WHEN lr.test_name = 'FEV1' AND CAST(lr.test_result AS DOUBLE) >= 80 THEN 'Normal (≥ 80%)'
    ELSE NULL
  END AS fev1_category,

  -- KRAS trial eligibility
  CASE
    WHEN lr.test_name = 'NGS Panel' AND lr.test_result LIKE '%KRAS G12C%' THEN TRUE
    ELSE FALSE
  END AS kras_g12c_trial_eligible,

  -- PD-L1 stratification for immunotherapy
  CASE
    WHEN lr.test_name = 'PD-L1 Expression' AND CAST(REPLACE(lr.test_result, '%', '') AS INT) > 50 THEN 'High Expression (>50%)'
    WHEN lr.test_name = 'PD-L1 Expression' AND CAST(REPLACE(lr.test_result, '%', '') AS INT) BETWEEN 1 AND 50 THEN 'Moderate Expression (1-50%)'
    WHEN lr.test_name = 'PD-L1 Expression' AND CAST(REPLACE(lr.test_result, '%', '') AS INT) < 1 THEN 'Low/Negative (<1%)'
    ELSE NULL
  END AS pdl1_expression_level,

  -- Clinical significance flag
  CASE
    WHEN lr.test_name IN ('FEV1', 'NGS Panel', 'PD-L1 Expression') AND lr.test_result != 'Normal' THEN 'Clinically Significant'
    WHEN lr.test_result != 'Normal' THEN 'Requires Review'
    ELSE 'Normal'
  END AS clinical_significance,

  -- Lab recency
  DATEDIFF(DAY, lr.lab_date, CURRENT_DATE()) AS days_since_test,

  CASE
    WHEN DATEDIFF(DAY, lr.lab_date, CURRENT_DATE()) <= 90 THEN 'Recent (< 90 days)'
    WHEN DATEDIFF(DAY, lr.lab_date, CURRENT_DATE()) <= 180 THEN 'Moderate (90-180 days)'
    ELSE 'Aged (> 180 days)'
  END AS test_recency_category,

  -- Data quality
  CASE
    WHEN lr.lab_id IS NULL OR lr.patient_id IS NULL THEN 'CRITICAL'
    WHEN lr.lab_date IS NULL OR lr.test_name IS NULL THEN 'WARNING'
    ELSE 'VALID'
  END AS data_quality_status,

  lr.created_at,
  CURRENT_TIMESTAMP() AS silver_load_timestamp
FROM hls_amer_catalog.r_health_bronze.lab_results lr
WHERE lr.lab_id IS NOT NULL;

SELECT 'Created Silver Lab Results Table:', COUNT(*) AS record_count
FROM hls_amer_catalog.r_health_silver.lab_results;

-- ============================================================================
-- 6. SILVER TIMELY FILING - Enriched Timely Filing with Deadline Tracking
-- ============================================================================
CREATE OR REPLACE TABLE hls_amer_catalog.r_health_silver.timely_filing AS
SELECT
  tf.claim_id,
  tf.patient_id,
  tf.service_date,
  tf.submission_date,
  tf.payer_name,
  tf.billed_amount,
  tf.filing_deadline,
  tf.days_to_deadline,
  tf.filing_status,
  tf.claim_status,
  tf.denial_reason,

  -- Filing urgency
  CASE
    WHEN tf.days_to_deadline < 0 THEN 'CRITICAL - Missed Deadline'
    WHEN tf.days_to_deadline <= 7 THEN 'CRITICAL - Due in 7 Days'
    WHEN tf.days_to_deadline <= 30 THEN 'HIGH - Due in 30 Days'
    WHEN tf.days_to_deadline <= 90 THEN 'MEDIUM - Due in 90 Days'
    ELSE 'LOW - On Track'
  END AS filing_urgency,

  -- Deadline compliance
  CASE
    WHEN tf.filing_status LIKE '%On Time%' AND tf.days_to_deadline >= 0 THEN 'Compliant - Timely'
    WHEN tf.filing_status = 'Past Deadline' THEN 'Non-Compliant - Late Filed'
    ELSE 'On Track'
  END AS compliance_status,

  -- Risk categorization by payer
  CASE
    WHEN tf.payer_name = 'Medicare' AND tf.days_to_deadline <= 30 THEN 'High Risk - Government Payer'
    WHEN tf.payer_name = 'Medicaid' AND tf.days_to_deadline <= 30 THEN 'High Risk - Government Payer'
    WHEN tf.days_to_deadline <= 7 THEN 'High Risk - Imminent Deadline'
    ELSE 'Standard Risk'
  END AS filing_risk_category,

  -- Days past due (for missed deadlines)
  CASE
    WHEN tf.days_to_deadline < 0 THEN ABS(tf.days_to_deadline)
    ELSE 0
  END AS days_past_due,

  -- Percentage of filing window used
  CASE
    WHEN tf.payer_name = 'Medicare' THEN ROUND(((365.0 - tf.days_to_deadline) / 365.0) * 100, 2)
    ELSE ROUND(((180.0 - tf.days_to_deadline) / 180.0) * 100, 2)
  END AS filing_window_used_percent,

  -- Data quality
  CASE
    WHEN tf.claim_id IS NULL THEN 'CRITICAL'
    WHEN tf.service_date IS NULL OR tf.filing_deadline IS NULL THEN 'WARNING'
    ELSE 'VALID'
  END AS data_quality_status,

  tf.created_at,
  CURRENT_TIMESTAMP() AS silver_load_timestamp
FROM hls_amer_catalog.r_health_bronze.timely_filing tf
WHERE tf.claim_id IS NOT NULL;

SELECT 'Created Silver Timely Filing Table:', COUNT(*) AS record_count
FROM hls_amer_catalog.r_health_silver.timely_filing;

-- ============================================================================
-- 7. SILVER DOCUMENTATION REQUESTS - Enriched Doc Request Tracking
-- ============================================================================
CREATE OR REPLACE TABLE hls_amer_catalog.r_health_silver.documentation_requests AS
SELECT
  dr.request_id,
  dr.claim_id,
  dr.patient_id,
  dr.service_date,
  dr.request_date,
  dr.completion_date,
  dr.payer_name,
  dr.documentation_type,
  dr.response_status,
  dr.days_to_respond,
  dr.billed_amount,
  dr.drg_code,

  -- Calculate due date (typically 10 business days from request)
  DATE_ADD(dr.request_date, 10) AS due_date,

  -- Days until due (for pending requests)
  CASE
    WHEN dr.response_status IN ('In Progress', 'Pending') THEN
      DATEDIFF(DAY, CURRENT_DATE(), DATE_ADD(dr.request_date, 10))
    ELSE NULL
  END AS days_until_due,

  -- Request urgency
  CASE
    WHEN dr.response_status IN ('In Progress', 'Pending') AND DATEDIFF(DAY, CURRENT_DATE(), DATE_ADD(dr.request_date, 10)) < 0 THEN 'CRITICAL - Overdue'
    WHEN dr.response_status IN ('In Progress', 'Pending') AND DATEDIFF(DAY, CURRENT_DATE(), DATE_ADD(dr.request_date, 10)) <= 3 THEN 'HIGH - Due in 3 Days'
    WHEN dr.response_status IN ('In Progress', 'Pending') AND DATEDIFF(DAY, CURRENT_DATE(), DATE_ADD(dr.request_date, 10)) <= 7 THEN 'MEDIUM - Due in 7 Days'
    WHEN dr.response_status IN ('In Progress', 'Pending') THEN 'LOW - On Track'
    ELSE 'Completed'
  END AS request_urgency,

  -- Response timeliness
  CASE
    WHEN dr.response_status = 'Completed' AND dr.days_to_respond <= 10 THEN 'On Time'
    WHEN dr.response_status = 'Completed' AND dr.days_to_respond > 10 THEN 'Late Submission'
    WHEN dr.response_status IN ('In Progress', 'Pending') AND DATEDIFF(DAY, dr.request_date, CURRENT_DATE()) > 10 THEN 'Overdue'
    ELSE 'Pending - On Track'
  END AS response_timeliness,

  -- Documentation complexity
  CASE
    WHEN dr.documentation_type IN ('Medical Records', 'Prior Authorization Documentation', 'Clinical Trial Protocol') THEN 'High Complexity'
    WHEN dr.documentation_type IN ('Physician Notes', 'Lab Results & Imaging') THEN 'Medium Complexity'
    ELSE 'Low Complexity'
  END AS documentation_complexity,

  -- Request age
  DATEDIFF(DAY, dr.request_date, CURRENT_DATE()) AS request_age_days,

  -- Data quality
  CASE
    WHEN dr.request_id IS NULL OR dr.claim_id IS NULL THEN 'CRITICAL'
    WHEN dr.request_date IS NULL THEN 'WARNING'
    ELSE 'VALID'
  END AS data_quality_status,

  dr.created_at,
  CURRENT_TIMESTAMP() AS silver_load_timestamp
FROM hls_amer_catalog.r_health_bronze.documentation_requests dr
WHERE dr.request_id IS NOT NULL;

SELECT 'Created Silver Documentation Requests Table:', COUNT(*) AS record_count
FROM hls_amer_catalog.r_health_silver.documentation_requests;

-- ============================================================================
-- SILVER LAYER VALIDATION & SUMMARY
-- ============================================================================
SELECT 'SILVER LAYER DATA TRANSFORMATION COMPLETE' AS status;

-- Data quality summary across all Silver tables
SELECT
  'Silver Layer Data Quality Summary' AS summary_type,
  (SELECT COUNT(*) FROM hls_amer_catalog.r_health_silver.patients WHERE data_quality_status = 'VALID') AS patients_valid,
  (SELECT COUNT(*) FROM hls_amer_catalog.r_health_silver.encounters WHERE data_quality_status = 'VALID') AS encounters_valid,
  (SELECT COUNT(*) FROM hls_amer_catalog.r_health_silver.claims WHERE data_quality_status = 'VALID') AS claims_valid,
  (SELECT COUNT(*) FROM hls_amer_catalog.r_health_silver.denials WHERE data_quality_status = 'VALID') AS denials_valid,
  (SELECT COUNT(*) FROM hls_amer_catalog.r_health_silver.lab_results WHERE data_quality_status = 'VALID') AS lab_results_valid,
  (SELECT COUNT(*) FROM hls_amer_catalog.r_health_silver.timely_filing WHERE data_quality_status = 'VALID') AS timely_filing_valid,
  (SELECT COUNT(*) FROM hls_amer_catalog.r_health_silver.documentation_requests WHERE data_quality_status = 'VALID') AS doc_requests_valid;
