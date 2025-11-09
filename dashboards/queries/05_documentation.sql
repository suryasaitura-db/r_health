-- ============================================================================
-- DOCUMENTATION MANAGEMENT DASHBOARD QUERIES
-- ============================================================================
-- Schema: hls_amer_catalog.r_health_gold.documentation_management
-- Purpose: Track documentation requests, completion rates, and turnaround times
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Query 1: Summary KPI Metrics
-- Business Value: Executive overview of documentation management performance
-- ----------------------------------------------------------------------------
-- Query Name: documentation_kpi_summary

SELECT
  SUM(total_requests) as total_requests,
  SUM(completed_requests) as completed_requests,
  SUM(pending_requests) as pending_requests,
  ROUND((SUM(completed_requests) / SUM(total_requests)) * 100, 1) as overall_completion_rate_pct,
  ROUND(AVG(avg_turnaround_days), 1) as avg_turnaround_days,
  ROUND(AVG(completion_rate) * 100, 1) as avg_completion_rate_pct,
  ROUND(SUM(associated_claim_value), 2) as total_claim_value,
  ROUND(SUM(CASE WHEN completion_rate < 0.80 THEN associated_claim_value ELSE 0 END), 2) as at_risk_claim_value,
  COUNT(DISTINCT payer_name) as unique_payers,
  COUNT(DISTINCT documentation_type) as unique_doc_types,
  SUM(CASE WHEN request_urgency = 'High' THEN total_requests ELSE 0 END) as high_urgency_requests,
  SUM(CASE WHEN request_urgency = 'Medium' THEN total_requests ELSE 0 END) as medium_urgency_requests
FROM hls_amer_catalog.r_health_gold.documentation_management;

-- ----------------------------------------------------------------------------
-- Query 2: Documentation Type Performance
-- Business Value: Identify documentation types with completion challenges
-- ----------------------------------------------------------------------------
-- Query Name: doc_type_performance

SELECT
  documentation_type,
  SUM(total_requests) as total_requests,
  SUM(completed_requests) as completed_requests,
  SUM(pending_requests) as pending_requests,
  ROUND((SUM(completed_requests) / SUM(total_requests)) * 100, 1) as completion_rate_pct,
  ROUND(AVG(avg_turnaround_days), 1) as avg_turnaround_days,
  ROUND(SUM(associated_claim_value), 2) as total_claim_value,
  COUNT(DISTINCT payer_name) as payers_requesting,
  ROUND(AVG(CASE WHEN request_urgency = 'High' THEN 1.0 ELSE 0.0 END) * 100, 1) as pct_high_urgency,
  CASE
    WHEN AVG(completion_rate) >= 0.90 THEN 'Excellent'
    WHEN AVG(completion_rate) >= 0.80 THEN 'Good'
    WHEN AVG(completion_rate) >= 0.70 THEN 'Fair'
    ELSE 'Needs Improvement'
  END as performance_tier
FROM hls_amer_catalog.r_health_gold.documentation_management
GROUP BY documentation_type
ORDER BY total_requests DESC, completion_rate_pct DESC;

-- ----------------------------------------------------------------------------
-- Query 3: Payer Documentation Requirements Analysis
-- Business Value: Understand payer-specific documentation burden and performance
-- ----------------------------------------------------------------------------
-- Query Name: payer_documentation_analysis

SELECT
  payer_name,
  COUNT(DISTINCT documentation_type) as doc_types_requested,
  SUM(total_requests) as total_requests,
  SUM(completed_requests) as completed_requests,
  SUM(pending_requests) as pending_requests,
  ROUND((SUM(completed_requests) / SUM(total_requests)) * 100, 1) as completion_rate_pct,
  ROUND(AVG(avg_turnaround_days), 1) as avg_turnaround_days,
  ROUND(SUM(associated_claim_value), 2) as total_claim_value,
  ROUND(SUM(associated_claim_value) / SUM(total_requests), 2) as avg_claim_value_per_request,
  SUM(CASE WHEN request_urgency = 'High' THEN total_requests ELSE 0 END) as high_urgency_count,
  ROUND((SUM(CASE WHEN request_urgency = 'High' THEN total_requests ELSE 0 END) / SUM(total_requests)) * 100, 1) as high_urgency_pct
FROM hls_amer_catalog.r_health_gold.documentation_management
GROUP BY payer_name
ORDER BY total_requests DESC
LIMIT 15;

-- ----------------------------------------------------------------------------
-- Query 4: Urgency Level Distribution
-- Business Value: Prioritize resources based on request urgency
-- ----------------------------------------------------------------------------
-- Query Name: urgency_level_breakdown

SELECT
  request_urgency,
  SUM(total_requests) as total_requests,
  SUM(completed_requests) as completed_requests,
  SUM(pending_requests) as pending_requests,
  ROUND((SUM(completed_requests) / SUM(total_requests)) * 100, 1) as completion_rate_pct,
  ROUND(AVG(avg_turnaround_days), 1) as avg_turnaround_days,
  ROUND(SUM(associated_claim_value), 2) as total_claim_value,
  COUNT(DISTINCT payer_name) as payers_affected,
  COUNT(DISTINCT documentation_type) as doc_types_affected,
  ROUND(SUM(associated_claim_value) / SUM(total_requests), 2) as avg_value_per_request
FROM hls_amer_catalog.r_health_gold.documentation_management
GROUP BY request_urgency
ORDER BY
  CASE request_urgency
    WHEN 'High' THEN 1
    WHEN 'Medium' THEN 2
    WHEN 'Low' THEN 3
    ELSE 4
  END;

-- ----------------------------------------------------------------------------
-- Query 5: Turnaround Time Performance Analysis
-- Business Value: Identify process bottlenecks and efficiency opportunities
-- ----------------------------------------------------------------------------
-- Query Name: turnaround_time_analysis

SELECT
  CASE
    WHEN avg_turnaround_days <= 2 THEN 'Excellent (0-2 Days)'
    WHEN avg_turnaround_days <= 5 THEN 'Good (3-5 Days)'
    WHEN avg_turnaround_days <= 10 THEN 'Fair (6-10 Days)'
    WHEN avg_turnaround_days <= 15 THEN 'Poor (11-15 Days)'
    ELSE 'Critical (15+ Days)'
  END as turnaround_category,
  COUNT(*) as record_count,
  SUM(total_requests) as total_requests,
  SUM(completed_requests) as completed_requests,
  ROUND((SUM(completed_requests) / SUM(total_requests)) * 100, 1) as completion_rate_pct,
  ROUND(AVG(avg_turnaround_days), 1) as avg_days,
  ROUND(SUM(associated_claim_value), 2) as total_claim_value,
  COUNT(DISTINCT payer_name) as payers_affected,
  SUM(CASE WHEN request_urgency = 'High' THEN total_requests ELSE 0 END) as high_urgency_requests
FROM hls_amer_catalog.r_health_gold.documentation_management
GROUP BY
  CASE
    WHEN avg_turnaround_days <= 2 THEN 'Excellent (0-2 Days)'
    WHEN avg_turnaround_days <= 5 THEN 'Good (3-5 Days)'
    WHEN avg_turnaround_days <= 10 THEN 'Fair (6-10 Days)'
    WHEN avg_turnaround_days <= 15 THEN 'Poor (11-15 Days)'
    ELSE 'Critical (15+ Days)'
  END
ORDER BY
  CASE
    WHEN avg_turnaround_days <= 2 THEN 1
    WHEN avg_turnaround_days <= 5 THEN 2
    WHEN avg_turnaround_days <= 10 THEN 3
    WHEN avg_turnaround_days <= 15 THEN 4
    ELSE 5
  END;

-- ----------------------------------------------------------------------------
-- Query 6: Completion Rate Performance Tiers
-- Business Value: Segment documentation types by completion performance
-- ----------------------------------------------------------------------------
-- Query Name: completion_rate_tiers

SELECT
  CASE
    WHEN completion_rate >= 0.95 THEN 'Outstanding (95%+)'
    WHEN completion_rate >= 0.90 THEN 'Excellent (90-95%)'
    WHEN completion_rate >= 0.80 THEN 'Good (80-90%)'
    WHEN completion_rate >= 0.70 THEN 'Fair (70-80%)'
    ELSE 'Needs Improvement (<70%)'
  END as performance_tier,
  COUNT(*) as record_count,
  SUM(total_requests) as total_requests,
  SUM(completed_requests) as completed_requests,
  SUM(pending_requests) as pending_requests,
  ROUND(AVG(completion_rate) * 100, 1) as avg_completion_rate_pct,
  ROUND(AVG(avg_turnaround_days), 1) as avg_turnaround_days,
  ROUND(SUM(associated_claim_value), 2) as total_claim_value,
  COUNT(DISTINCT documentation_type) as doc_types,
  COUNT(DISTINCT payer_name) as payers
FROM hls_amer_catalog.r_health_gold.documentation_management
GROUP BY
  CASE
    WHEN completion_rate >= 0.95 THEN 'Outstanding (95%+)'
    WHEN completion_rate >= 0.90 THEN 'Excellent (90-95%)'
    WHEN completion_rate >= 0.80 THEN 'Good (80-90%)'
    WHEN completion_rate >= 0.70 THEN 'Fair (70-80%)'
    ELSE 'Needs Improvement (<70%)'
  END
ORDER BY
  CASE
    WHEN completion_rate >= 0.95 THEN 1
    WHEN completion_rate >= 0.90 THEN 2
    WHEN completion_rate >= 0.80 THEN 3
    WHEN completion_rate >= 0.70 THEN 4
    ELSE 5
  END;

-- ----------------------------------------------------------------------------
-- Query 7: High-Value Documentation Requests
-- Business Value: Focus on documentation linked to high-value claims
-- ----------------------------------------------------------------------------
-- Query Name: high_value_documentation_tracking

SELECT
  payer_name,
  documentation_type,
  request_urgency,
  SUM(total_requests) as total_requests,
  SUM(completed_requests) as completed_requests,
  SUM(pending_requests) as pending_requests,
  ROUND((SUM(completed_requests) / SUM(total_requests)) * 100, 1) as completion_rate_pct,
  ROUND(AVG(avg_turnaround_days), 1) as avg_turnaround_days,
  ROUND(SUM(associated_claim_value), 2) as total_claim_value,
  ROUND(AVG(associated_claim_value / total_requests), 2) as avg_value_per_request,
  CASE
    WHEN AVG(completion_rate) < 0.80 AND AVG(avg_turnaround_days) > 10 THEN 'High Risk'
    WHEN AVG(completion_rate) < 0.80 OR AVG(avg_turnaround_days) > 10 THEN 'Medium Risk'
    ELSE 'Low Risk'
  END as risk_level
FROM hls_amer_catalog.r_health_gold.documentation_management
WHERE associated_claim_value >= 10000
GROUP BY payer_name, documentation_type, request_urgency
HAVING SUM(pending_requests) > 0
ORDER BY total_claim_value DESC, completion_rate_pct ASC
LIMIT 25;

-- ----------------------------------------------------------------------------
-- Query 8: Detailed Documentation Management Table
-- Business Value: Comprehensive operational view for team management
-- ----------------------------------------------------------------------------
-- Query Name: detailed_documentation_tracker

SELECT
  payer_name,
  documentation_type,
  request_urgency,
  total_requests,
  completed_requests,
  pending_requests,
  ROUND(completion_rate * 100, 1) as completion_rate_pct,
  ROUND(avg_turnaround_days, 1) as avg_turnaround_days,
  ROUND(associated_claim_value, 2) as claim_value,
  ROUND(associated_claim_value / total_requests, 2) as value_per_request,
  CASE
    WHEN completion_rate >= 0.90 AND avg_turnaround_days <= 5 THEN 'Excellent Performance'
    WHEN completion_rate >= 0.80 AND avg_turnaround_days <= 10 THEN 'Good Performance'
    WHEN completion_rate >= 0.70 OR avg_turnaround_days <= 15 THEN 'Fair Performance'
    ELSE 'Needs Improvement'
  END as performance_status,
  CASE
    WHEN request_urgency = 'High' AND pending_requests > 5 THEN 'Critical - Prioritize'
    WHEN request_urgency = 'High' AND completion_rate < 0.80 THEN 'High - Improve Process'
    WHEN pending_requests > 10 THEN 'Medium - Resource Allocation'
    ELSE 'Low - Monitor'
  END as action_priority,
  CASE
    WHEN pending_requests > 0 THEN ROUND((pending_requests / total_requests) * 100, 1)
    ELSE 0
  END as pending_pct
FROM hls_amer_catalog.r_health_gold.documentation_management
ORDER BY
  CASE request_urgency
    WHEN 'High' THEN 1
    WHEN 'Medium' THEN 2
    ELSE 3
  END,
  pending_requests DESC,
  associated_claim_value DESC
LIMIT 100;

-- ----------------------------------------------------------------------------
-- Query 9: Payer-Documentation Type Matrix
-- Business Value: Identify payer-specific documentation patterns and challenges
-- ----------------------------------------------------------------------------
-- Query Name: payer_doctype_matrix

SELECT
  payer_name,
  documentation_type,
  SUM(total_requests) as total_requests,
  ROUND((SUM(completed_requests) / SUM(total_requests)) * 100, 1) as completion_rate_pct,
  ROUND(AVG(avg_turnaround_days), 1) as avg_turnaround_days,
  SUM(pending_requests) as pending_requests,
  ROUND(SUM(associated_claim_value), 2) as claim_value,
  request_urgency as primary_urgency,
  CASE
    WHEN (SUM(completed_requests) / SUM(total_requests)) < 0.70 THEN 'Process Review Needed'
    WHEN AVG(avg_turnaround_days) > 15 THEN 'Efficiency Improvement Needed'
    WHEN SUM(pending_requests) > 10 THEN 'Resource Allocation Needed'
    ELSE 'Performing Well'
  END as improvement_area
FROM hls_amer_catalog.r_health_gold.documentation_management
GROUP BY payer_name, documentation_type, request_urgency
HAVING SUM(total_requests) >= 5
ORDER BY total_requests DESC, completion_rate_pct ASC
LIMIT 30;
