-- ============================================================================
-- DENIALS MANAGEMENT DASHBOARD QUERIES
-- ============================================================================
-- Schema: hls_amer_catalog.r_health_gold.denials_management
-- Purpose: Track denial rates, appeal success, revenue recovery, and payer performance
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Query 1: Summary KPI Metrics
-- Business Value: Executive-level overview of denials and appeals performance
-- ----------------------------------------------------------------------------
-- Query Name: denials_kpi_summary

SELECT
  SUM(total_denials) as total_denials,
  SUM(total_appealed) as total_appealed,
  ROUND(AVG(denial_rate) * 100, 2) as avg_denial_rate_pct,
  ROUND(AVG(appeal_win_rate) * 100, 2) as avg_appeal_win_rate_pct,
  ROUND(SUM(total_denied_amount), 2) as total_denied_amount,
  ROUND(SUM(recovered_amount), 2) as total_recovered_amount,
  ROUND((SUM(recovered_amount) / SUM(total_denied_amount)) * 100, 2) as recovery_rate_pct,
  ROUND(SUM(total_denied_amount) - SUM(recovered_amount), 2) as revenue_at_risk,
  COUNT(DISTINCT payer_name) as unique_payers,
  COUNT(DISTINCT drg_code) as unique_drgs,
  ROUND(AVG(priority_score), 2) as avg_priority_score
FROM hls_amer_catalog.r_health_gold.denials_management;

-- ----------------------------------------------------------------------------
-- Query 2: Top Denial Categories
-- Business Value: Identify primary root causes of denials for focused intervention
-- ----------------------------------------------------------------------------
-- Query Name: top_denial_categories

SELECT
  denial_category,
  SUM(total_denials) as total_denials,
  SUM(total_appealed) as total_appealed,
  ROUND((SUM(total_appealed) / SUM(total_denials)) * 100, 1) as appeal_rate_pct,
  ROUND(AVG(appeal_win_rate) * 100, 1) as avg_win_rate_pct,
  ROUND(SUM(total_denied_amount), 2) as total_denied_amount,
  ROUND(SUM(recovered_amount), 2) as recovered_amount,
  ROUND((SUM(recovered_amount) / SUM(total_denied_amount)) * 100, 1) as recovery_rate_pct,
  ROUND(AVG(priority_score), 1) as avg_priority_score
FROM hls_amer_catalog.r_health_gold.denials_management
GROUP BY denial_category
ORDER BY total_denied_amount DESC;

-- ----------------------------------------------------------------------------
-- Query 3: Payer Performance Analysis
-- Business Value: Identify problematic payers and negotiate better contracts
-- ----------------------------------------------------------------------------
-- Query Name: payer_performance_ranking

SELECT
  payer_name,
  COUNT(DISTINCT drg_code) as unique_drgs,
  SUM(total_denials) as total_denials,
  ROUND(AVG(denial_rate) * 100, 2) as avg_denial_rate_pct,
  SUM(total_appealed) as total_appealed,
  ROUND(AVG(appeal_win_rate) * 100, 2) as avg_win_rate_pct,
  ROUND(SUM(total_denied_amount), 2) as total_denied_amount,
  ROUND(SUM(recovered_amount), 2) as recovered_amount,
  ROUND(SUM(total_denied_amount) - SUM(recovered_amount), 2) as net_revenue_loss,
  ROUND(AVG(priority_score), 1) as avg_priority_score
FROM hls_amer_catalog.r_health_gold.denials_management
GROUP BY payer_name
ORDER BY total_denied_amount DESC
LIMIT 15;

-- ----------------------------------------------------------------------------
-- Query 4: Denial Rate Distribution
-- Business Value: Understand the distribution of denial rates across DRG-Payer combinations
-- ----------------------------------------------------------------------------
-- Query Name: denial_rate_distribution

SELECT
  CASE
    WHEN denial_rate >= 0.20 THEN 'Critical (20%+)'
    WHEN denial_rate >= 0.10 THEN 'High (10-20%)'
    WHEN denial_rate >= 0.05 THEN 'Medium (5-10%)'
    ELSE 'Low (<5%)'
  END as denial_rate_category,
  COUNT(*) as record_count,
  SUM(total_denials) as total_denials,
  ROUND(AVG(denial_rate) * 100, 2) as avg_denial_rate_pct,
  ROUND(SUM(total_denied_amount), 2) as total_denied_amount,
  ROUND(AVG(appeal_win_rate) * 100, 2) as avg_win_rate_pct,
  ROUND(SUM(recovered_amount), 2) as recovered_amount
FROM hls_amer_catalog.r_health_gold.denials_management
GROUP BY
  CASE
    WHEN denial_rate >= 0.20 THEN 'Critical (20%+)'
    WHEN denial_rate >= 0.10 THEN 'High (10-20%)'
    WHEN denial_rate >= 0.05 THEN 'Medium (5-10%)'
    ELSE 'Low (<5%)'
  END
ORDER BY
  CASE
    WHEN denial_rate >= 0.20 THEN 1
    WHEN denial_rate >= 0.10 THEN 2
    WHEN denial_rate >= 0.05 THEN 3
    ELSE 4
  END;

-- ----------------------------------------------------------------------------
-- Query 5: Appeal Win Rate Analysis
-- Business Value: Identify which denial categories and payers have highest appeal success
-- ----------------------------------------------------------------------------
-- Query Name: appeal_success_analysis

SELECT
  denial_category,
  payer_name,
  SUM(total_denials) as total_denials,
  SUM(total_appealed) as total_appealed,
  ROUND((SUM(total_appealed) / SUM(total_denials)) * 100, 1) as appeal_rate_pct,
  ROUND(AVG(appeal_win_rate) * 100, 1) as avg_win_rate_pct,
  ROUND(SUM(total_denied_amount), 2) as denied_amount,
  ROUND(SUM(recovered_amount), 2) as recovered_amount,
  CASE
    WHEN AVG(appeal_win_rate) >= 0.70 THEN 'High Success'
    WHEN AVG(appeal_win_rate) >= 0.50 THEN 'Moderate Success'
    WHEN AVG(appeal_win_rate) >= 0.30 THEN 'Low Success'
    ELSE 'Very Low Success'
  END as appeal_success_tier
FROM hls_amer_catalog.r_health_gold.denials_management
WHERE total_appealed > 0
GROUP BY denial_category, payer_name
ORDER BY avg_win_rate_pct DESC, recovered_amount DESC
LIMIT 20;

-- ----------------------------------------------------------------------------
-- Query 6: High Priority Denial Records
-- Business Value: Focus on highest-priority denial issues for immediate action
-- ----------------------------------------------------------------------------
-- Query Name: high_priority_denials

SELECT
  drg_code,
  payer_name,
  denial_category,
  total_denials,
  ROUND(denial_rate * 100, 2) as denial_rate_pct,
  total_appealed,
  ROUND(appeal_win_rate * 100, 2) as win_rate_pct,
  ROUND(total_denied_amount, 2) as denied_amount,
  ROUND(recovered_amount, 2) as recovered_amount,
  ROUND(total_denied_amount - recovered_amount, 2) as unrecovered_amount,
  ROUND(priority_score, 2) as priority_score,
  CASE
    WHEN priority_score >= 80 THEN 'Critical Priority'
    WHEN priority_score >= 60 THEN 'High Priority'
    WHEN priority_score >= 40 THEN 'Medium Priority'
    ELSE 'Low Priority'
  END as priority_tier
FROM hls_amer_catalog.r_health_gold.denials_management
WHERE priority_score >= 60
ORDER BY priority_score DESC, total_denied_amount DESC
LIMIT 25;

-- ----------------------------------------------------------------------------
-- Query 7: Revenue Recovery Opportunities
-- Business Value: Identify areas with low recovery rates but high dollar potential
-- ----------------------------------------------------------------------------
-- Query Name: recovery_opportunities

SELECT
  denial_category,
  payer_name,
  drg_code,
  SUM(total_denials) as total_denials,
  SUM(total_appealed) as total_appealed,
  ROUND(SUM(total_denied_amount), 2) as total_denied_amount,
  ROUND(SUM(recovered_amount), 2) as recovered_amount,
  ROUND(SUM(total_denied_amount) - SUM(recovered_amount), 2) as unrecovered_amount,
  ROUND((SUM(recovered_amount) / SUM(total_denied_amount)) * 100, 1) as recovery_rate_pct,
  ROUND(AVG(appeal_win_rate) * 100, 1) as avg_win_rate_pct,
  ROUND(AVG(priority_score), 1) as priority_score
FROM hls_amer_catalog.r_health_gold.denials_management
GROUP BY denial_category, payer_name, drg_code
HAVING SUM(total_denied_amount) - SUM(recovered_amount) > 5000
  AND (SUM(recovered_amount) / SUM(total_denied_amount)) < 0.50
ORDER BY unrecovered_amount DESC
LIMIT 20;

-- ----------------------------------------------------------------------------
-- Query 8: Payer-Category Denial Matrix
-- Business Value: Understand denial patterns across payer-category combinations
-- ----------------------------------------------------------------------------
-- Query Name: payer_category_matrix

SELECT
  payer_name,
  denial_category,
  COUNT(DISTINCT drg_code) as affected_drgs,
  SUM(total_denials) as total_denials,
  ROUND(AVG(denial_rate) * 100, 2) as avg_denial_rate_pct,
  ROUND(SUM(total_denied_amount), 2) as total_denied_amount,
  ROUND(SUM(recovered_amount), 2) as recovered_amount,
  ROUND(AVG(appeal_win_rate) * 100, 1) as avg_win_rate_pct,
  ROUND((SUM(total_appealed) / SUM(total_denials)) * 100, 1) as appeal_rate_pct
FROM hls_amer_catalog.r_health_gold.denials_management
GROUP BY payer_name, denial_category
HAVING SUM(total_denials) >= 10
ORDER BY total_denied_amount DESC
LIMIT 30;
