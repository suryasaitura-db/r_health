-- ============================================================================
-- TIMELY FILING & APPEALS DASHBOARD QUERIES
-- ============================================================================
-- Schema: hls_amer_catalog.r_health_gold.timely_filing_appeals
-- Purpose: Monitor claims at risk of timely filing deadlines and compliance
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Query 1: Summary KPI Metrics
-- Business Value: Executive overview of timely filing risk and compliance
-- ----------------------------------------------------------------------------
-- Query Name: timely_filing_kpi_summary

SELECT
  COUNT(DISTINCT claim_id) as total_claims,
  COUNT(CASE WHEN is_at_risk = true THEN 1 END) as claims_at_risk,
  ROUND((COUNT(CASE WHEN is_at_risk = true THEN 1 END) / COUNT(*)) * 100, 1) as at_risk_rate_pct,
  ROUND(SUM(claim_amount), 2) as total_claim_value,
  ROUND(SUM(at_risk_amount), 2) as total_at_risk_amount,
  ROUND((SUM(at_risk_amount) / SUM(claim_amount)) * 100, 1) as at_risk_value_pct,
  COUNT(DISTINCT payer_name) as unique_payers,
  ROUND(AVG(days_to_deadline), 1) as avg_days_to_deadline,
  COUNT(CASE WHEN compliance_status = 'Critical' THEN 1 END) as critical_claims,
  COUNT(CASE WHEN compliance_status = 'Warning' THEN 1 END) as warning_claims,
  COUNT(CASE WHEN compliance_status = 'Compliant' THEN 1 END) as compliant_claims,
  ROUND(AVG(urgency_score), 1) as avg_urgency_score
FROM hls_amer_catalog.r_health_gold.timely_filing_appeals;

-- ----------------------------------------------------------------------------
-- Query 2: Compliance Status Distribution
-- Business Value: Understand urgency distribution to prioritize resources
-- ----------------------------------------------------------------------------
-- Query Name: compliance_status_breakdown

SELECT
  compliance_status,
  COUNT(DISTINCT claim_id) as claim_count,
  ROUND((COUNT(*) / (SELECT COUNT(*) FROM hls_amer_catalog.r_health_gold.timely_filing_appeals)) * 100, 1) as pct_of_total,
  COUNT(DISTINCT payer_name) as payers_affected,
  ROUND(SUM(claim_amount), 2) as total_claim_value,
  ROUND(SUM(at_risk_amount), 2) as at_risk_amount,
  ROUND(AVG(days_to_deadline), 1) as avg_days_to_deadline,
  MIN(days_to_deadline) as min_days_to_deadline,
  MAX(days_to_deadline) as max_days_to_deadline,
  ROUND(AVG(urgency_score), 1) as avg_urgency_score
FROM hls_amer_catalog.r_health_gold.timely_filing_appeals
GROUP BY compliance_status
ORDER BY
  CASE compliance_status
    WHEN 'Critical' THEN 1
    WHEN 'Warning' THEN 2
    WHEN 'Compliant' THEN 3
    ELSE 4
  END;

-- ----------------------------------------------------------------------------
-- Query 3: Payer Risk Analysis
-- Business Value: Identify payers with highest timely filing risk
-- ----------------------------------------------------------------------------
-- Query Name: payer_risk_ranking

SELECT
  payer_name,
  COUNT(DISTINCT claim_id) as total_claims,
  COUNT(CASE WHEN is_at_risk = true THEN 1 END) as at_risk_claims,
  ROUND((COUNT(CASE WHEN is_at_risk = true THEN 1 END) / COUNT(*)) * 100, 1) as at_risk_rate_pct,
  ROUND(SUM(claim_amount), 2) as total_claim_value,
  ROUND(SUM(at_risk_amount), 2) as at_risk_amount,
  ROUND((SUM(at_risk_amount) / SUM(claim_amount)) * 100, 1) as at_risk_value_pct,
  ROUND(AVG(days_to_deadline), 1) as avg_days_to_deadline,
  COUNT(CASE WHEN compliance_status = 'Critical' THEN 1 END) as critical_claims,
  COUNT(CASE WHEN compliance_status = 'Warning' THEN 1 END) as warning_claims,
  ROUND(AVG(urgency_score), 1) as avg_urgency_score
FROM hls_amer_catalog.r_health_gold.timely_filing_appeals
GROUP BY payer_name
ORDER BY at_risk_amount DESC, at_risk_rate_pct DESC
LIMIT 15;

-- ----------------------------------------------------------------------------
-- Query 4: Critical Claims Requiring Immediate Action
-- Business Value: Action list for revenue cycle team to prevent write-offs
-- ----------------------------------------------------------------------------
-- Query Name: critical_claims_action_list

SELECT
  claim_id,
  payer_name,
  ROUND(claim_amount, 2) as claim_amount,
  days_to_deadline,
  compliance_status,
  CASE WHEN is_at_risk = true THEN 'Yes' ELSE 'No' END as at_risk,
  ROUND(at_risk_amount, 2) as at_risk_amount,
  ROUND(urgency_score, 1) as urgency_score,
  CASE
    WHEN days_to_deadline <= 3 THEN 'File Today'
    WHEN days_to_deadline <= 7 THEN 'File This Week'
    WHEN days_to_deadline <= 14 THEN 'File Within 2 Weeks'
    ELSE 'Monitor'
  END as action_required
FROM hls_amer_catalog.r_health_gold.timely_filing_appeals
WHERE compliance_status IN ('Critical', 'Warning')
ORDER BY urgency_score DESC, days_to_deadline ASC, claim_amount DESC
LIMIT 50;

-- ----------------------------------------------------------------------------
-- Query 5: Days to Deadline Distribution
-- Business Value: Understand timeline pressure across claim portfolio
-- ----------------------------------------------------------------------------
-- Query Name: deadline_timeline_distribution

SELECT
  CASE
    WHEN days_to_deadline <= 0 THEN 'Past Deadline (0 or negative)'
    WHEN days_to_deadline <= 3 THEN '0-3 Days (Critical)'
    WHEN days_to_deadline <= 7 THEN '4-7 Days (Urgent)'
    WHEN days_to_deadline <= 14 THEN '8-14 Days (Warning)'
    WHEN days_to_deadline <= 30 THEN '15-30 Days (Monitor)'
    ELSE '30+ Days (Safe)'
  END as deadline_bucket,
  COUNT(DISTINCT claim_id) as claim_count,
  ROUND(SUM(claim_amount), 2) as total_claim_value,
  ROUND(SUM(at_risk_amount), 2) as at_risk_amount,
  COUNT(DISTINCT payer_name) as payers_affected,
  ROUND(AVG(urgency_score), 1) as avg_urgency_score,
  COUNT(CASE WHEN is_at_risk = true THEN 1 END) as at_risk_count
FROM hls_amer_catalog.r_health_gold.timely_filing_appeals
GROUP BY
  CASE
    WHEN days_to_deadline <= 0 THEN 'Past Deadline (0 or negative)'
    WHEN days_to_deadline <= 3 THEN '0-3 Days (Critical)'
    WHEN days_to_deadline <= 7 THEN '4-7 Days (Urgent)'
    WHEN days_to_deadline <= 14 THEN '8-14 Days (Warning)'
    WHEN days_to_deadline <= 30 THEN '15-30 Days (Monitor)'
    ELSE '30+ Days (Safe)'
  END
ORDER BY
  CASE
    WHEN days_to_deadline <= 0 THEN 1
    WHEN days_to_deadline <= 3 THEN 2
    WHEN days_to_deadline <= 7 THEN 3
    WHEN days_to_deadline <= 14 THEN 4
    WHEN days_to_deadline <= 30 THEN 5
    ELSE 6
  END;

-- ----------------------------------------------------------------------------
-- Query 6: Revenue at Risk Analysis
-- Business Value: Quantify financial exposure from timely filing issues
-- ----------------------------------------------------------------------------
-- Query Name: revenue_risk_quantification

SELECT
  CASE
    WHEN at_risk_amount >= 50000 THEN 'Very High ($50K+)'
    WHEN at_risk_amount >= 25000 THEN 'High ($25K-$50K)'
    WHEN at_risk_amount >= 10000 THEN 'Medium ($10K-$25K)'
    WHEN at_risk_amount > 0 THEN 'Low ($0-$10K)'
    ELSE 'No Risk'
  END as risk_amount_category,
  COUNT(DISTINCT claim_id) as claim_count,
  ROUND(SUM(claim_amount), 2) as total_claim_value,
  ROUND(SUM(at_risk_amount), 2) as total_at_risk,
  ROUND(AVG(days_to_deadline), 1) as avg_days_to_deadline,
  COUNT(CASE WHEN compliance_status = 'Critical' THEN 1 END) as critical_count,
  COUNT(CASE WHEN compliance_status = 'Warning' THEN 1 END) as warning_count,
  ROUND(AVG(urgency_score), 1) as avg_urgency_score
FROM hls_amer_catalog.r_health_gold.timely_filing_appeals
GROUP BY
  CASE
    WHEN at_risk_amount >= 50000 THEN 'Very High ($50K+)'
    WHEN at_risk_amount >= 25000 THEN 'High ($25K-$50K)'
    WHEN at_risk_amount >= 10000 THEN 'Medium ($10K-$25K)'
    WHEN at_risk_amount > 0 THEN 'Low ($0-$10K)'
    ELSE 'No Risk'
  END
ORDER BY
  CASE
    WHEN at_risk_amount >= 50000 THEN 1
    WHEN at_risk_amount >= 25000 THEN 2
    WHEN at_risk_amount >= 10000 THEN 3
    WHEN at_risk_amount > 0 THEN 4
    ELSE 5
  END;

-- ----------------------------------------------------------------------------
-- Query 7: Urgency Score Trend Analysis
-- Business Value: Prioritize claims using composite urgency scoring
-- ----------------------------------------------------------------------------
-- Query Name: urgency_score_prioritization

SELECT
  CASE
    WHEN urgency_score >= 90 THEN 'Extreme Urgency (90+)'
    WHEN urgency_score >= 70 THEN 'High Urgency (70-89)'
    WHEN urgency_score >= 50 THEN 'Medium Urgency (50-69)'
    WHEN urgency_score >= 30 THEN 'Low Urgency (30-49)'
    ELSE 'Routine (Under 30)'
  END as urgency_category,
  COUNT(DISTINCT claim_id) as claim_count,
  ROUND(SUM(claim_amount), 2) as total_claim_value,
  ROUND(SUM(at_risk_amount), 2) as total_at_risk,
  ROUND(AVG(days_to_deadline), 1) as avg_days_to_deadline,
  COUNT(DISTINCT payer_name) as payers_affected,
  COUNT(CASE WHEN is_at_risk = true THEN 1 END) as at_risk_claims,
  COUNT(CASE WHEN compliance_status = 'Critical' THEN 1 END) as critical_claims
FROM hls_amer_catalog.r_health_gold.timely_filing_appeals
GROUP BY
  CASE
    WHEN urgency_score >= 90 THEN 'Extreme Urgency (90+)'
    WHEN urgency_score >= 70 THEN 'High Urgency (70-89)'
    WHEN urgency_score >= 50 THEN 'Medium Urgency (50-69)'
    WHEN urgency_score >= 30 THEN 'Low Urgency (30-49)'
    ELSE 'Routine (Under 30)'
  END
ORDER BY
  CASE
    WHEN urgency_score >= 90 THEN 1
    WHEN urgency_score >= 70 THEN 2
    WHEN urgency_score >= 50 THEN 3
    WHEN urgency_score >= 30 THEN 4
    ELSE 5
  END;

-- ----------------------------------------------------------------------------
-- Query 8: Detailed Timely Filing Tracking Table
-- Business Value: Comprehensive view for operational tracking and management
-- ----------------------------------------------------------------------------
-- Query Name: detailed_filing_tracker

SELECT
  claim_id,
  payer_name,
  ROUND(claim_amount, 2) as claim_amount,
  days_to_deadline,
  CASE WHEN is_at_risk = true THEN 'At Risk' ELSE 'Not At Risk' END as risk_status,
  ROUND(at_risk_amount, 2) as at_risk_amount,
  compliance_status,
  ROUND(urgency_score, 1) as urgency_score,
  CASE
    WHEN days_to_deadline <= 0 THEN 'OVERDUE - File Appeal Immediately'
    WHEN days_to_deadline <= 3 THEN 'CRITICAL - File Within 24 Hours'
    WHEN days_to_deadline <= 7 THEN 'URGENT - File This Week'
    WHEN days_to_deadline <= 14 THEN 'WARNING - File Within 2 Weeks'
    WHEN days_to_deadline <= 30 THEN 'MONITOR - File Within Month'
    ELSE 'ON TRACK'
  END as recommended_action,
  CASE
    WHEN days_to_deadline <= 3 AND claim_amount >= 25000 THEN 'Top Priority'
    WHEN days_to_deadline <= 7 AND claim_amount >= 10000 THEN 'High Priority'
    WHEN is_at_risk = true THEN 'Medium Priority'
    ELSE 'Standard Priority'
  END as workflow_priority
FROM hls_amer_catalog.r_health_gold.timely_filing_appeals
ORDER BY urgency_score DESC, days_to_deadline ASC, claim_amount DESC
LIMIT 100;
