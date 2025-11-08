-- ================================================================================
-- BRONZE LAYER: SYNTHETIC HEALTHCARE DATA GENERATION
-- Renown Health RFP Demo - Option A (Synthetic Data)
-- ================================================================================
-- This script generates realistic synthetic healthcare data for 5 scenarios:
-- 1. Capacity Management (GMLOS, Readmissions)
-- 2. Denials Management (Claims, Pre-Auth, Appeals)
-- 3. Clinical Trial Matching (Genomics, Lab Results)
-- 4. Timely Filing & Appeals
-- 5. Additional Documentation Requests
-- ================================================================================

-- Create Bronze schema
CREATE SCHEMA IF NOT EXISTS hls_amer_catalog.r_health_bronze
COMMENT 'Bronze layer - Raw synthetic healthcare data for Renown Health demo scenarios';

-- ================================================================================
-- TABLE 1: PATIENTS (Master Patient Index)
-- ================================================================================
CREATE OR REPLACE TABLE hls_amer_catalog.r_health_bronze.patients AS
WITH patient_base AS (
  SELECT
    CONCAT('PT', LPAD(CAST(id AS STRING), 8, '0')) AS patient_id,
    id,
    CASE
      WHEN MOD(id, 100) < 45 THEN 'Female'
      WHEN MOD(id, 100) < 90 THEN 'Male'
      ELSE 'Other'
    END AS gender,
    CASE
      WHEN MOD(id, 100) < 13 THEN CONCAT('2003-', LPAD(CAST(MOD(id, 12) + 1 AS STRING), 2, '0'), '-15')
      WHEN MOD(id, 100) < 25 THEN CONCAT('1985-', LPAD(CAST(MOD(id, 12) + 1 AS STRING), 2, '0'), '-10')
      WHEN MOD(id, 100) < 45 THEN CONCAT('1970-', LPAD(CAST(MOD(id, 12) + 1 AS STRING), 2, '0'), '-05')
      WHEN MOD(id, 100) < 70 THEN CONCAT('1955-', LPAD(CAST(MOD(id, 12) + 1 AS STRING), 2, '0'), '-20')
      ELSE CONCAT('1940-', LPAD(CAST(MOD(id, 12) + 1 AS STRING), 2, '0'), '-28')
    END AS date_of_birth,
    CASE
      WHEN MOD(id, 100) < 70 THEN 'White'
      WHEN MOD(id, 100) < 85 THEN 'Black or African American'
      WHEN MOD(id, 100) < 92 THEN 'Asian'
      ELSE 'Other'
    END AS race,
    CASE
      WHEN MOD(id, 100) < 15 THEN 'Hispanic or Latino'
      ELSE 'Not Hispanic or Latino'
    END AS ethnicity,
    CONCAT(
      LPAD(CAST(MOD(id * 7 + 123, 900) + 100 AS STRING), 3, '0'), '-',
      LPAD(CAST(MOD(id * 11 + 456, 90) + 10 AS STRING), 2, '0'), '-',
      LPAD(CAST(MOD(id * 13 + 789, 9000) + 1000 AS STRING), 4, '0')
    ) AS ssn,
    -- KRAS mutation status for clinical trial matching (Scenario 3)
    CASE
      WHEN MOD(id, 1000) < 25 THEN 'KRAS G12C Positive'
      WHEN MOD(id, 1000) < 50 THEN 'KRAS G12D Positive'
      WHEN MOD(id, 1000) < 100 THEN 'KRAS WT'
      ELSE 'Not Tested'
    END AS kras_mutation_status,
    -- COPD severity for clinical trial matching
    CASE
      WHEN MOD(id, 1000) < 150 THEN 'Severe COPD (FEV1 < 30%)'
      WHEN MOD(id, 1000) < 300 THEN 'Moderate COPD (FEV1 30-49%)'
      WHEN MOD(id, 1000) < 500 THEN 'Mild COPD (FEV1 50-79%)'
      ELSE 'No COPD'
    END AS copd_severity,
    CURRENT_TIMESTAMP() AS created_at,
    'SYNTHETIC_DATA_GEN' AS source_system
  FROM RANGE(50000) -- 50,000 patients
)
SELECT * FROM patient_base;

SELECT 'Created Patients Table:', COUNT(*) AS record_count FROM hls_amer_catalog.r_health_bronze.patients;

-- ================================================================================
-- TABLE 2: HOSPITAL ENCOUNTERS (Admissions, ED Visits, Observations)
-- ================================================================================
CREATE OR REPLACE TABLE hls_amer_catalog.r_health_bronze.encounters AS
WITH date_generator AS (
  SELECT
    DATE_ADD(DATE '2023-01-01', CAST(id AS INT)) AS encounter_date
  FROM RANGE(730) -- 2 years of data
),
encounter_base AS (
  SELECT
    CONCAT('ENC', LPAD(CAST(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date, 0.5) AS STRING), 10, '0')) AS encounter_id,
    p.patient_id,
    d.encounter_date AS admission_date,
    -- Encounter type distribution matching RFP (50k ED, 10k Observation, 20k Inpatient annually)
    CASE
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 100) < 62 THEN 'Emergency'
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 100) < 75 THEN 'Observation'
      ELSE 'Inpatient'
    END AS encounter_type,
    -- DRG codes (Diagnosis Related Groups) for capacity planning
    CASE
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 50) < 5 THEN '470' -- Major Hip/Knee Joint Replacement
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 50) < 10 THEN '871' -- Septicemia without MV >96 hours
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 50) < 15 THEN '291' -- Heart Failure & Shock
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 50) < 20 THEN '194' -- Simple Pneumonia & Pleurisy
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 50) < 25 THEN '392' -- Esophagitis & Gastroenteritis
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 50) < 30 THEN '641' -- Nutritional & Metabolic Disorders
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 50) < 35 THEN '690' -- Kidney & Urinary Tract Infections
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 50) < 40 THEN '765' -- Cesarean Section
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 50) < 45 THEN '775' -- Vaginal Delivery
      ELSE CONCAT(CAST(CAST(MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 100) / 100.0 * 900 + 100 AS INT) AS STRING))
    END AS drg_code,
    -- Length of Stay (LOS) with variation for GMLOS analysis
    CASE
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 100) < 62 THEN CAST(MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 100) / 100.0 * 0.5 + 0.1 AS DECIMAL(5,2)) -- ED: 0.1-0.6 days
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 100) < 75 THEN CAST(MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 100) / 100.0 * 1.5 + 0.5 AS DECIMAL(5,2)) -- Observation: 0.5-2 days
      ELSE CAST(MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 100) / 100.0 * 8 + 2 AS DECIMAL(5,2)) -- Inpatient: 2-10 days
    END AS length_of_stay,
    -- Discharge disposition
    CASE
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 100) < 75 THEN 'Home'
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 100) < 85 THEN 'Skilled Nursing Facility'
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 100) < 92 THEN 'Home Health Care'
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 100) < 97 THEN 'Rehab Facility'
      ELSE 'Expired'
    END AS discharge_disposition,
    -- Readmission flag (for 30-day readmission analysis)
    CASE
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 100) < 18 THEN TRUE
      ELSE FALSE
    END AS is_30day_readmission,
    -- Primary diagnosis (ICD-10)
    CASE
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 30) < 3 THEN 'I50.9' -- Heart Failure
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 30) < 6 THEN 'J18.9' -- Pneumonia
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 30) < 9 THEN 'A41.9' -- Sepsis
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 30) < 12 THEN 'J44.1' -- COPD with exacerbation
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 30) < 15 THEN 'C34.90' -- Lung Cancer (NSCLC)
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 30) < 18 THEN 'E11.9' -- Type 2 Diabetes
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 30) < 21 THEN 'I21.9' -- Myocardial Infarction
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 30) < 24 THEN 'N18.3' -- Chronic Kidney Disease
      ELSE CONCAT('Z', LPAD(CAST(CAST(MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 100) / 100.0 * 90 + 10 AS INT) AS STRING), 2, '0'), '.', CAST(CAST(MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date) + 1, 9) AS INT) AS STRING))
    END AS primary_diagnosis_code,
    CAST(MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, d.encounter_date), 100) / 100.0 * 50000 + 5000 AS DECIMAL(10,2)) AS total_charges,
    CURRENT_TIMESTAMP() AS created_at
  FROM hls_amer_catalog.r_health_bronze.patients p
  CROSS JOIN date_generator d
  WHERE MOD(HASH(CONCAT(p.patient_id, CAST(d.encounter_date AS STRING))), 100) / 100.0 < 0.35 -- ~35% of patient-days result in encounters
)
SELECT
  encounter_id,
  patient_id,
  admission_date,
  DATE_ADD(admission_date, CAST(length_of_stay AS INT)) AS discharge_date,
  encounter_type,
  drg_code,
  length_of_stay,
  discharge_disposition,
  is_30day_readmission,
  primary_diagnosis_code,
  total_charges,
  created_at
FROM encounter_base;

SELECT 'Created Encounters Table:', COUNT(*) AS record_count FROM hls_amer_catalog.r_health_bronze.encounters;

-- ================================================================================
-- TABLE 3: CLAIMS (Insurance Claims for Denials Management)
-- ================================================================================
CREATE OR REPLACE TABLE hls_amer_catalog.r_health_bronze.claims AS
WITH claims_base AS (
  SELECT
    CONCAT('CLM', LPAD(CAST(ROW_NUMBER() OVER (ORDER BY encounter_id) AS STRING), 10, '0')) AS claim_id,
    encounter_id,
    patient_id,
    admission_date AS service_date,
    DATE_ADD(admission_date, CAST(MOD(ROW_NUMBER() OVER (ORDER BY encounter_id), 100) / 100.0 * 30 + 5 AS INT)) AS submission_date,
    -- Payer mix (40% Medicare, 30% Medicaid, 30% Commercial)
    CASE
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY encounter_id), 100) < 40 THEN 'Medicare'
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY encounter_id), 100) < 70 THEN 'Medicaid'
      ELSE 'Commercial'
    END AS payer_name,
    CASE
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY encounter_id), 100) < 40 THEN CONCAT('MC-', LPAD(CAST(CAST(MOD(ROW_NUMBER() OVER (ORDER BY encounter_id), 100) / 100.0 * 9000000 + 1000000 AS INT) AS STRING), 7, '0'))
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY encounter_id), 100) < 70 THEN CONCAT('MD-', LPAD(CAST(CAST(MOD(ROW_NUMBER() OVER (ORDER BY encounter_id), 100) / 100.0 * 9000000 + 1000000 AS INT) AS STRING), 7, '0'))
      ELSE CONCAT('COM-', LPAD(CAST(CAST(MOD(ROW_NUMBER() OVER (ORDER BY encounter_id), 100) / 100.0 * 9000000 + 1000000 AS INT) AS STRING), 7, '0'))
    END AS payer_claim_number,
    total_charges AS billed_amount,
    CASE
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY encounter_id), 100) < 75 THEN total_charges * 0.85 -- 85% allowed
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY encounter_id), 100) < 90 THEN total_charges * 0.60 -- 60% allowed (some denials)
      ELSE 0 -- Full denial
    END AS allowed_amount,
    -- Claim status
    CASE
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY encounter_id), 100) < 70 THEN 'Paid'
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY encounter_id), 100) < 85 THEN 'Partially Paid'
      ELSE 'Denied'
    END AS claim_status,
    -- Denial reason (for denied/partial claims)
    CASE
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY encounter_id), 100) >= 70 THEN
        CASE
          WHEN MOD(ROW_NUMBER() OVER (ORDER BY encounter_id), 20) < 5 THEN 'Medical Necessity Not Met'
          WHEN MOD(ROW_NUMBER() OVER (ORDER BY encounter_id), 20) < 10 THEN 'Lack of Prior Authorization'
          WHEN MOD(ROW_NUMBER() OVER (ORDER BY encounter_id), 20) < 13 THEN 'Insufficient Documentation'
          WHEN MOD(ROW_NUMBER() OVER (ORDER BY encounter_id), 20) < 16 THEN 'Incorrect Coding'
          ELSE 'Service Not Covered'
        END
      ELSE NULL
    END AS denial_reason,
    -- Pre-authorization flag
    CASE
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY encounter_id), 100) < 65 THEN TRUE
      ELSE FALSE
    END AS has_prior_auth,
    drg_code,
    primary_diagnosis_code,
    CURRENT_TIMESTAMP() AS created_at
  FROM hls_amer_catalog.r_health_bronze.encounters
)
SELECT
  claim_id,
  encounter_id,
  patient_id,
  service_date,
  submission_date,
  payer_name,
  payer_claim_number,
  billed_amount,
  allowed_amount,
  CAST((allowed_amount * 0.20) AS DECIMAL(10,2)) AS patient_responsibility,
  CAST((allowed_amount * 0.80) AS DECIMAL(10,2)) AS paid_amount,
  claim_status,
  denial_reason,
  has_prior_auth,
  drg_code,
  primary_diagnosis_code,
  created_at
FROM claims_base;

SELECT 'Created Claims Table:', COUNT(*) AS record_count FROM hls_amer_catalog.r_health_bronze.claims;

-- ================================================================================
-- TABLE 4: DENIALS (Detailed Denial Tracking)
-- ================================================================================
CREATE OR REPLACE TABLE hls_amer_catalog.r_health_bronze.denials AS
WITH denials_base AS (
  SELECT
    CONCAT('DEN', LPAD(CAST(ROW_NUMBER() OVER (ORDER BY claim_id) AS STRING), 10, '0')) AS denial_id,
    claim_id,
    patient_id,
    service_date,
    submission_date,
    DATE_ADD(submission_date, CAST(MOD(ROW_NUMBER() OVER (ORDER BY claim_id), 100) / 100.0 * 15 + 7 AS INT)) AS denial_date,
    payer_name,
    billed_amount,
    denial_reason,
    -- Appeal status
    CASE
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY claim_id), 100) < 60 THEN 'Appealed'
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY claim_id), 100) < 80 THEN 'Pending Review'
      ELSE 'Not Appealed'
    END AS appeal_status,
    -- Appeal outcome (for appealed claims)
    CASE
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY claim_id), 100) < 60 THEN
        CASE
          WHEN MOD(ROW_NUMBER() OVER (ORDER BY claim_id), 10) < 7 THEN 'Overturned - Paid in Full'
          WHEN MOD(ROW_NUMBER() OVER (ORDER BY claim_id), 10) < 9 THEN 'Partially Overturned'
          ELSE 'Upheld - Remained Denied'
        END
      ELSE NULL
    END AS appeal_outcome,
    drg_code,
    primary_diagnosis_code,
    CURRENT_TIMESTAMP() AS created_at
  FROM hls_amer_catalog.r_health_bronze.claims
  WHERE claim_status IN ('Denied', 'Partially Paid')
)
SELECT * FROM denials_base;

SELECT 'Created Denials Table:', COUNT(*) AS record_count FROM hls_amer_catalog.r_health_bronze.denials;

-- ================================================================================
-- TABLE 5: LAB RESULTS (For Clinical Trial Matching - Scenario 3)
-- ================================================================================
CREATE OR REPLACE TABLE hls_amer_catalog.r_health_bronze.lab_results AS
WITH lab_base AS (
  SELECT
    CONCAT('LAB', LPAD(CAST(ROW_NUMBER() OVER (ORDER BY p.patient_id, e.encounter_id) AS STRING), 12, '0')) AS lab_id,
    e.encounter_id,
    e.patient_id,
    e.admission_date AS lab_date,
    -- Lab test types
    CASE
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, e.encounter_id), 10) < 2 THEN 'FEV1' -- Forced Expiratory Volume (COPD screening)
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, e.encounter_id), 10) < 4 THEN 'NGS Panel' -- Next-Gen Sequencing for KRAS
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, e.encounter_id), 10) < 6 THEN 'PD-L1 Expression'
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, e.encounter_id), 10) < 8 THEN 'Complete Blood Count'
      ELSE 'Metabolic Panel'
    END AS test_name,
    -- Test values (realistic ranges)
    CASE
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, e.encounter_id), 10) < 2 THEN -- FEV1 (% predicted)
        CASE
          WHEN p.copd_severity = 'Severe COPD (FEV1 < 30%)' THEN CAST(MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, e.encounter_id), 100) / 100.0 * 15 + 10 AS STRING)
          WHEN p.copd_severity = 'Moderate COPD (FEV1 30-49%)' THEN CAST(MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, e.encounter_id), 100) / 100.0 * 19 + 30 AS STRING)
          WHEN p.copd_severity = 'Mild COPD (FEV1 50-79%)' THEN CAST(MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, e.encounter_id), 100) / 100.0 * 29 + 50 AS STRING)
          ELSE CAST(MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, e.encounter_id), 100) / 100.0 * 20 + 80 AS STRING)
        END
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, e.encounter_id), 10) < 4 THEN -- NGS/KRAS
        p.kras_mutation_status
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, e.encounter_id), 10) < 6 THEN -- PD-L1
        CONCAT(CAST(CAST(MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, e.encounter_id), 100) / 100.0 * 100 AS INT) AS STRING), '%')
      ELSE 'Normal'
    END AS test_result,
    CASE
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, e.encounter_id), 10) < 2 THEN '%'
      WHEN MOD(ROW_NUMBER() OVER (ORDER BY p.patient_id, e.encounter_id), 10) < 6 THEN 'Qualitative'
      ELSE 'mg/dL'
    END AS result_unit,
    CURRENT_TIMESTAMP() AS created_at
  FROM hls_amer_catalog.r_health_bronze.patients p
  INNER JOIN hls_amer_catalog.r_health_bronze.encounters e ON p.patient_id = e.patient_id
  WHERE MOD(HASH(CONCAT(p.patient_id, e.encounter_id)), 100) / 100.0 < 0.40 -- 40% of encounters have labs
)
SELECT * FROM lab_base;

SELECT 'Created Lab Results Table:', COUNT(*) AS record_count FROM hls_amer_catalog.r_health_bronze.lab_results;

-- ================================================================================
-- TABLE 6: TIMELY FILING TRACKER (Scenario 4)
-- ================================================================================
CREATE OR REPLACE TABLE hls_amer_catalog.r_health_bronze.timely_filing AS
WITH filing_base AS (
  SELECT
    claim_id,
    patient_id,
    service_date,
    submission_date,
    payer_name,
    billed_amount,
    -- Timely filing deadline (180 days for most payers)
    DATE_ADD(service_date, CASE
      WHEN payer_name = 'Medicare' THEN 365
      WHEN payer_name = 'Medicaid' THEN 180
      ELSE 180
    END) AS filing_deadline,
    -- Days to deadline
    DATEDIFF(
      DATE_ADD(service_date, CASE
        WHEN payer_name = 'Medicare' THEN 365
        WHEN payer_name = 'Medicaid' THEN 180
        ELSE 180
      END),
      submission_date
    ) AS days_to_deadline,
    -- Filing status
    CASE
      WHEN DATEDIFF(
        DATE_ADD(service_date, CASE
          WHEN payer_name = 'Medicare' THEN 365
          WHEN payer_name = 'Medicaid' THEN 180
          ELSE 180
        END),
        submission_date
      ) > 60 THEN 'On Time - Low Risk'
      WHEN DATEDIFF(
        DATE_ADD(service_date, CASE
          WHEN payer_name = 'Medicare' THEN 365
          WHEN payer_name = 'Medicaid' THEN 180
          ELSE 180
        END),
        submission_date
      ) > 30 THEN 'On Time - Medium Risk'
      WHEN DATEDIFF(
        DATE_ADD(service_date, CASE
          WHEN payer_name = 'Medicare' THEN 365
          WHEN payer_name = 'Medicaid' THEN 180
          ELSE 180
        END),
        submission_date
      ) >= 0 THEN 'On Time - High Risk'
      ELSE 'Past Deadline'
    END AS filing_status,
    claim_status,
    denial_reason,
    CURRENT_TIMESTAMP() AS created_at
  FROM hls_amer_catalog.r_health_bronze.claims
)
SELECT * FROM filing_base;

SELECT 'Created Timely Filing Table:', COUNT(*) AS record_count FROM hls_amer_catalog.r_health_bronze.timely_filing;

-- ================================================================================
-- TABLE 7: DOCUMENTATION REQUESTS (Scenario 5)
-- ================================================================================
CREATE OR REPLACE TABLE hls_amer_catalog.r_health_bronze.documentation_requests AS
WITH doc_requests_ranked AS (
  SELECT
    c.*,
    ROW_NUMBER() OVER (ORDER BY c.claim_id) AS row_num
  FROM hls_amer_catalog.r_health_bronze.claims c
),
doc_requests AS (
  SELECT
    CONCAT('DOC', LPAD(CAST(row_num AS STRING), 10, '0')) AS request_id,
    claim_id,
    patient_id,
    service_date,
    DATE_ADD(submission_date, CAST(MOD(row_num, 100) / 100.0 * 20 + 5 AS INT)) AS request_date,
    payer_name,
    -- Documentation type requested
    CASE
      WHEN MOD(row_num, 10) < 3 THEN 'Medical Records'
      WHEN MOD(row_num, 10) < 5 THEN 'Physician Notes'
      WHEN MOD(row_num, 10) < 7 THEN 'Lab Results & Imaging'
      WHEN MOD(row_num, 10) < 9 THEN 'Prior Authorization Documentation'
      ELSE 'Clinical Trial Protocol'
    END AS documentation_type,
    -- Response status
    CASE
      WHEN MOD(row_num, 100) < 65 THEN 'Completed'
      WHEN MOD(row_num, 100) < 85 THEN 'In Progress'
      ELSE 'Pending'
    END AS response_status,
    -- Days to respond
    CASE
      WHEN MOD(row_num, 100) < 65 THEN CAST(MOD(row_num, 100) / 100.0 * 10 + 2 AS INT)
      ELSE NULL
    END AS days_to_respond,
    billed_amount,
    drg_code,
    CURRENT_TIMESTAMP() AS created_at
  FROM doc_requests_ranked
  WHERE MOD(row_num, 100) < 35 -- 35% of claims have doc requests
)
SELECT
  request_id,
  claim_id,
  patient_id,
  service_date,
  request_date,
  CASE
    WHEN response_status = 'Completed' THEN DATE_ADD(request_date, days_to_respond)
    ELSE NULL
  END AS completion_date,
  payer_name,
  documentation_type,
  response_status,
  days_to_respond,
  billed_amount,
  drg_code,
  created_at
FROM doc_requests;

SELECT 'Created Documentation Requests Table:', COUNT(*) AS record_count FROM hls_amer_catalog.r_health_bronze.documentation_requests;

-- ================================================================================
-- VERIFICATION QUERIES
-- ================================================================================
SELECT 'BRONZE LAYER DATA GENERATION COMPLETE' AS status;

-- Summary of all Bronze tables
SELECT 'patients' AS table_name, COUNT(*) AS records FROM hls_amer_catalog.r_health_bronze.patients
UNION ALL
SELECT 'encounters', COUNT(*) FROM hls_amer_catalog.r_health_bronze.encounters
UNION ALL
SELECT 'claims', COUNT(*) FROM hls_amer_catalog.r_health_bronze.claims
UNION ALL
SELECT 'denials', COUNT(*) FROM hls_amer_catalog.r_health_bronze.denials
UNION ALL
SELECT 'lab_results', COUNT(*) FROM hls_amer_catalog.r_health_bronze.lab_results
UNION ALL
SELECT 'timely_filing', COUNT(*) FROM hls_amer_catalog.r_health_bronze.timely_filing
UNION ALL
SELECT 'documentation_requests', COUNT(*) FROM hls_amer_catalog.r_health_bronze.documentation_requests;
