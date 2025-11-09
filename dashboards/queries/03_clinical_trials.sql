-- ============================================================================
-- CLINICAL TRIAL MATCHING DASHBOARD QUERIES
-- ============================================================================
-- Schema: hls_amer_catalog.r_health_gold.clinical_trial_matching
-- Purpose: Identify eligible patients for clinical trials and enrollment opportunities
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Query 1: Summary KPI Metrics
-- Business Value: Overview of trial eligibility across patient population
-- ----------------------------------------------------------------------------
-- Query Name: trial_matching_kpi_summary

SELECT
  COUNT(DISTINCT patient_id) as total_patients,
  COUNT(DISTINCT primary_diagnosis) as unique_diagnoses,
  COUNT(CASE WHEN eligible_trial_count > 0 THEN 1 END) as patients_with_eligibility,
  ROUND((COUNT(CASE WHEN eligible_trial_count > 0 THEN 1 END) / COUNT(*)) * 100, 1) as eligibility_rate_pct,
  SUM(eligible_trial_count) as total_trial_matches,
  ROUND(AVG(eligible_trial_count), 2) as avg_trials_per_patient,
  COUNT(CASE WHEN kras_trial_eligible = true THEN 1 END) as kras_eligible_count,
  COUNT(CASE WHEN copd_trial_eligible = true THEN 1 END) as copd_eligible_count,
  COUNT(CASE WHEN pdl1_trial_eligible = true THEN 1 END) as pdl1_eligible_count,
  ROUND(AVG(patient_age), 1) as avg_patient_age
FROM hls_amer_catalog.r_health_gold.clinical_trial_matching;

-- ----------------------------------------------------------------------------
-- Query 2: Eligibility by Trial Type
-- Business Value: Understand distribution of patients across different trial types
-- ----------------------------------------------------------------------------
-- Query Name: trial_type_distribution

SELECT
  'KRAS Mutation Trials' as trial_type,
  COUNT(CASE WHEN kras_trial_eligible = true THEN 1 END) as eligible_patients,
  COUNT(CASE WHEN kras_mutated = true THEN 1 END) as biomarker_positive,
  ROUND(AVG(CASE WHEN kras_trial_eligible = true THEN patient_age END), 1) as avg_age_eligible,
  COUNT(DISTINCT CASE WHEN kras_trial_eligible = true THEN primary_diagnosis END) as diagnoses_represented
FROM hls_amer_catalog.r_health_gold.clinical_trial_matching

UNION ALL

SELECT
  'COPD Clinical Trials' as trial_type,
  COUNT(CASE WHEN copd_trial_eligible = true THEN 1 END) as eligible_patients,
  COUNT(CASE WHEN copd_diagnosis = true THEN 1 END) as biomarker_positive,
  ROUND(AVG(CASE WHEN copd_trial_eligible = true THEN patient_age END), 1) as avg_age_eligible,
  COUNT(DISTINCT CASE WHEN copd_trial_eligible = true THEN primary_diagnosis END) as diagnoses_represented
FROM hls_amer_catalog.r_health_gold.clinical_trial_matching

UNION ALL

SELECT
  'PDL1 Expression Trials' as trial_type,
  COUNT(CASE WHEN pdl1_trial_eligible = true THEN 1 END) as eligible_patients,
  COUNT(CASE WHEN pdl1_expression IS NOT NULL THEN 1 END) as biomarker_positive,
  ROUND(AVG(CASE WHEN pdl1_trial_eligible = true THEN patient_age END), 1) as avg_age_eligible,
  COUNT(DISTINCT CASE WHEN pdl1_trial_eligible = true THEN primary_diagnosis END) as diagnoses_represented
FROM hls_amer_catalog.r_health_gold.clinical_trial_matching

ORDER BY eligible_patients DESC;

-- ----------------------------------------------------------------------------
-- Query 3: Age Distribution of Eligible Patients
-- Business Value: Understand age demographics for trial recruitment planning
-- ----------------------------------------------------------------------------
-- Query Name: age_distribution_analysis

SELECT
  CASE
    WHEN patient_age < 30 THEN 'Under 30'
    WHEN patient_age < 40 THEN '30-39'
    WHEN patient_age < 50 THEN '40-49'
    WHEN patient_age < 60 THEN '50-59'
    WHEN patient_age < 70 THEN '60-69'
    ELSE '70+'
  END as age_group,
  COUNT(*) as total_patients,
  COUNT(CASE WHEN eligible_trial_count > 0 THEN 1 END) as eligible_patients,
  ROUND((COUNT(CASE WHEN eligible_trial_count > 0 THEN 1 END) / COUNT(*)) * 100, 1) as eligibility_rate_pct,
  SUM(eligible_trial_count) as total_trial_matches,
  ROUND(AVG(eligible_trial_count), 2) as avg_trials_per_patient,
  COUNT(CASE WHEN kras_trial_eligible = true THEN 1 END) as kras_eligible,
  COUNT(CASE WHEN copd_trial_eligible = true THEN 1 END) as copd_eligible,
  COUNT(CASE WHEN pdl1_trial_eligible = true THEN 1 END) as pdl1_eligible
FROM hls_amer_catalog.r_health_gold.clinical_trial_matching
GROUP BY
  CASE
    WHEN patient_age < 30 THEN 'Under 30'
    WHEN patient_age < 40 THEN '30-39'
    WHEN patient_age < 50 THEN '40-49'
    WHEN patient_age < 60 THEN '50-59'
    WHEN patient_age < 70 THEN '60-69'
    ELSE '70+'
  END
ORDER BY age_group;

-- ----------------------------------------------------------------------------
-- Query 4: Diagnosis-Based Trial Opportunities
-- Business Value: Identify diagnoses with highest trial enrollment potential
-- ----------------------------------------------------------------------------
-- Query Name: diagnosis_trial_opportunities

SELECT
  primary_diagnosis,
  COUNT(DISTINCT patient_id) as total_patients,
  COUNT(CASE WHEN eligible_trial_count > 0 THEN 1 END) as eligible_patients,
  ROUND((COUNT(CASE WHEN eligible_trial_count > 0 THEN 1 END) / COUNT(*)) * 100, 1) as eligibility_rate_pct,
  SUM(eligible_trial_count) as total_trial_matches,
  ROUND(AVG(eligible_trial_count), 2) as avg_trials_per_patient,
  COUNT(CASE WHEN kras_trial_eligible = true THEN 1 END) as kras_eligible,
  COUNT(CASE WHEN copd_trial_eligible = true THEN 1 END) as copd_eligible,
  COUNT(CASE WHEN pdl1_trial_eligible = true THEN 1 END) as pdl1_eligible,
  ROUND(AVG(patient_age), 1) as avg_patient_age
FROM hls_amer_catalog.r_health_gold.clinical_trial_matching
GROUP BY primary_diagnosis
HAVING COUNT(DISTINCT patient_id) >= 5
ORDER BY eligible_patients DESC, total_trial_matches DESC
LIMIT 20;

-- ----------------------------------------------------------------------------
-- Query 5: Multi-Trial Eligible Patients
-- Business Value: Identify patients eligible for multiple trials (high-value recruits)
-- ----------------------------------------------------------------------------
-- Query Name: multi_trial_eligible_patients

SELECT
  CASE
    WHEN eligible_trial_count >= 3 THEN '3+ Trials'
    WHEN eligible_trial_count = 2 THEN '2 Trials'
    WHEN eligible_trial_count = 1 THEN '1 Trial'
    ELSE 'Not Eligible'
  END as eligibility_category,
  COUNT(*) as patient_count,
  ROUND(AVG(patient_age), 1) as avg_age,
  COUNT(CASE WHEN patient_gender = 'Male' THEN 1 END) as male_count,
  COUNT(CASE WHEN patient_gender = 'Female' THEN 1 END) as female_count,
  COUNT(DISTINCT primary_diagnosis) as unique_diagnoses,
  SUM(CASE WHEN kras_trial_eligible = true THEN 1 ELSE 0 END) as kras_eligible,
  SUM(CASE WHEN copd_trial_eligible = true THEN 1 ELSE 0 END) as copd_eligible,
  SUM(CASE WHEN pdl1_trial_eligible = true THEN 1 ELSE 0 END) as pdl1_eligible
FROM hls_amer_catalog.r_health_gold.clinical_trial_matching
GROUP BY
  CASE
    WHEN eligible_trial_count >= 3 THEN '3+ Trials'
    WHEN eligible_trial_count = 2 THEN '2 Trials'
    WHEN eligible_trial_count = 1 THEN '1 Trial'
    ELSE 'Not Eligible'
  END
ORDER BY
  CASE
    WHEN eligible_trial_count >= 3 THEN 1
    WHEN eligible_trial_count = 2 THEN 2
    WHEN eligible_trial_count = 1 THEN 3
    ELSE 4
  END;

-- ----------------------------------------------------------------------------
-- Query 6: Gender Distribution in Trial Eligibility
-- Business Value: Ensure diverse trial enrollment across gender demographics
-- ----------------------------------------------------------------------------
-- Query Name: gender_eligibility_analysis

SELECT
  patient_gender,
  COUNT(*) as total_patients,
  COUNT(CASE WHEN eligible_trial_count > 0 THEN 1 END) as eligible_patients,
  ROUND((COUNT(CASE WHEN eligible_trial_count > 0 THEN 1 END) / COUNT(*)) * 100, 1) as eligibility_rate_pct,
  ROUND(AVG(patient_age), 1) as avg_age,
  SUM(eligible_trial_count) as total_trial_matches,
  COUNT(CASE WHEN kras_trial_eligible = true THEN 1 END) as kras_eligible,
  COUNT(CASE WHEN copd_trial_eligible = true THEN 1 END) as copd_eligible,
  COUNT(CASE WHEN pdl1_trial_eligible = true THEN 1 END) as pdl1_eligible,
  COUNT(DISTINCT primary_diagnosis) as unique_diagnoses
FROM hls_amer_catalog.r_health_gold.clinical_trial_matching
GROUP BY patient_gender
ORDER BY total_patients DESC;

-- ----------------------------------------------------------------------------
-- Query 7: Biomarker Positive Patients Detail
-- Business Value: Detailed list of biomarker-positive patients for outreach
-- ----------------------------------------------------------------------------
-- Query Name: biomarker_positive_patients

SELECT
  patient_id,
  patient_age,
  patient_gender,
  primary_diagnosis,
  CASE WHEN kras_mutated = true THEN 'Yes' ELSE 'No' END as kras_mutated,
  CASE WHEN kras_trial_eligible = true THEN 'Yes' ELSE 'No' END as kras_eligible,
  CASE WHEN copd_diagnosis = true THEN 'Yes' ELSE 'No' END as copd_diagnosis,
  CASE WHEN copd_trial_eligible = true THEN 'Yes' ELSE 'No' END as copd_eligible,
  pdl1_expression,
  CASE WHEN pdl1_trial_eligible = true THEN 'Yes' ELSE 'No' END as pdl1_eligible,
  eligible_trial_count,
  CASE
    WHEN eligible_trial_count >= 3 THEN 'High Priority'
    WHEN eligible_trial_count >= 2 THEN 'Medium Priority'
    WHEN eligible_trial_count >= 1 THEN 'Standard Priority'
    ELSE 'Not Eligible'
  END as recruitment_priority
FROM hls_amer_catalog.r_health_gold.clinical_trial_matching
WHERE kras_mutated = true OR copd_diagnosis = true OR pdl1_expression IS NOT NULL
ORDER BY eligible_trial_count DESC, patient_age
LIMIT 100;

-- ----------------------------------------------------------------------------
-- Query 8: Trial Eligibility Funnel Analysis
-- Business Value: Understand conversion from diagnosis to eligibility
-- ----------------------------------------------------------------------------
-- Query Name: eligibility_funnel_analysis

SELECT
  primary_diagnosis,
  COUNT(DISTINCT patient_id) as total_patients,

  -- KRAS pathway
  COUNT(CASE WHEN kras_mutated = true THEN 1 END) as kras_mutated_count,
  COUNT(CASE WHEN kras_trial_eligible = true THEN 1 END) as kras_eligible_count,
  ROUND((COUNT(CASE WHEN kras_trial_eligible = true THEN 1 END) /
    NULLIF(COUNT(CASE WHEN kras_mutated = true THEN 1 END), 0)) * 100, 1) as kras_conversion_rate,

  -- COPD pathway
  COUNT(CASE WHEN copd_diagnosis = true THEN 1 END) as copd_diagnosis_count,
  COUNT(CASE WHEN copd_trial_eligible = true THEN 1 END) as copd_eligible_count,
  ROUND((COUNT(CASE WHEN copd_trial_eligible = true THEN 1 END) /
    NULLIF(COUNT(CASE WHEN copd_diagnosis = true THEN 1 END), 0)) * 100, 1) as copd_conversion_rate,

  -- PDL1 pathway
  COUNT(CASE WHEN pdl1_expression IS NOT NULL THEN 1 END) as pdl1_tested_count,
  COUNT(CASE WHEN pdl1_trial_eligible = true THEN 1 END) as pdl1_eligible_count,
  ROUND((COUNT(CASE WHEN pdl1_trial_eligible = true THEN 1 END) /
    NULLIF(COUNT(CASE WHEN pdl1_expression IS NOT NULL THEN 1 END), 0)) * 100, 1) as pdl1_conversion_rate,

  -- Overall
  COUNT(CASE WHEN eligible_trial_count > 0 THEN 1 END) as overall_eligible,
  ROUND((COUNT(CASE WHEN eligible_trial_count > 0 THEN 1 END) / COUNT(*)) * 100, 1) as overall_eligibility_rate

FROM hls_amer_catalog.r_health_gold.clinical_trial_matching
GROUP BY primary_diagnosis
HAVING COUNT(DISTINCT patient_id) >= 10
ORDER BY total_patients DESC
LIMIT 15;
