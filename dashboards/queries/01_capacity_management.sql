-- ============================================================================
-- CAPACITY MANAGEMENT DASHBOARD QUERIES
-- ============================================================================
-- Schema: hls_amer_catalog.r_health_gold.capacity_management
-- Purpose: Analyze bed utilization, length of stay optimization, and cost opportunities
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Query 1: Summary KPI Metrics
-- Business Value: High-level overview of capacity optimization opportunities
-- ----------------------------------------------------------------------------
-- Query Name: capacity_kpi_summary

SELECT
  COUNT(DISTINCT drg_code) as total_drg_codes,
  SUM(total_encounters) as total_encounters,
  ROUND(AVG(avg_los), 2) as overall_avg_los,
  ROUND(AVG(gmlos_benchmark), 2) as overall_gmlos_benchmark,
  SUM(total_bed_days) as total_bed_days,
  ROUND(SUM(estimated_cost_opportunity), 2) as total_cost_opportunity,
  COUNT(CASE WHEN optimization_priority = 'High' THEN 1 END) as high_priority_drgs,
  COUNT(CASE WHEN optimization_priority = 'Medium' THEN 1 END) as medium_priority_drgs,
  COUNT(CASE WHEN optimization_priority = 'Low' THEN 1 END) as low_priority_drgs,
  ROUND(AVG(avg_los - gmlos_benchmark), 2) as avg_los_variance
FROM hls_amer_catalog.r_health_gold.capacity_management;

-- ----------------------------------------------------------------------------
-- Query 2: Top 10 Cost Opportunity DRGs
-- Business Value: Identify highest-impact areas for capacity optimization
-- ----------------------------------------------------------------------------
-- Query Name: top_cost_opportunities

SELECT
  drg_code,
  primary_diagnosis_code,
  total_encounters,
  ROUND(avg_los, 2) as avg_los,
  ROUND(gmlos_benchmark, 2) as gmlos_benchmark,
  ROUND(avg_los - gmlos_benchmark, 2) as los_variance,
  total_bed_days,
  ROUND(estimated_cost_opportunity, 2) as cost_opportunity,
  optimization_priority
FROM hls_amer_catalog.r_health_gold.capacity_management
WHERE estimated_cost_opportunity > 0
ORDER BY estimated_cost_opportunity DESC
LIMIT 10;

-- ----------------------------------------------------------------------------
-- Query 3: Optimization Priority Distribution
-- Business Value: Understand distribution of optimization priorities across DRGs
-- ----------------------------------------------------------------------------
-- Query Name: priority_distribution

SELECT
  optimization_priority,
  COUNT(*) as drg_count,
  SUM(total_encounters) as total_encounters,
  ROUND(AVG(avg_los), 2) as avg_los,
  ROUND(SUM(estimated_cost_opportunity), 2) as total_cost_opportunity,
  ROUND(AVG(estimated_cost_opportunity), 2) as avg_cost_opportunity_per_drg
FROM hls_amer_catalog.r_health_gold.capacity_management
GROUP BY optimization_priority
ORDER BY
  CASE optimization_priority
    WHEN 'High' THEN 1
    WHEN 'Medium' THEN 2
    WHEN 'Low' THEN 3
    ELSE 4
  END;

-- ----------------------------------------------------------------------------
-- Query 4: Length of Stay Performance Analysis
-- Business Value: Compare actual vs benchmark LOS to identify efficiency gaps
-- ----------------------------------------------------------------------------
-- Query Name: los_performance_analysis

SELECT
  drg_code,
  primary_diagnosis_code,
  total_encounters,
  ROUND(avg_los, 2) as actual_avg_los,
  ROUND(gmlos_benchmark, 2) as benchmark_gmlos,
  ROUND(avg_los - gmlos_benchmark, 2) as los_variance,
  ROUND(((avg_los - gmlos_benchmark) / gmlos_benchmark) * 100, 1) as los_variance_pct,
  total_bed_days,
  ROUND(total_bed_days * (avg_los - gmlos_benchmark) / avg_los, 0) as excess_bed_days,
  optimization_priority
FROM hls_amer_catalog.r_health_gold.capacity_management
WHERE avg_los > gmlos_benchmark
ORDER BY los_variance_pct DESC
LIMIT 20;

-- ----------------------------------------------------------------------------
-- Query 5: Encounter Volume vs Cost Opportunity
-- Business Value: Identify high-volume DRGs with significant optimization potential
-- ----------------------------------------------------------------------------
-- Query Name: volume_opportunity_matrix

SELECT
  CASE
    WHEN total_encounters >= 100 THEN 'High Volume (100+)'
    WHEN total_encounters >= 50 THEN 'Medium Volume (50-99)'
    ELSE 'Low Volume (<50)'
  END as volume_category,
  CASE
    WHEN estimated_cost_opportunity >= 50000 THEN 'High Opportunity ($50K+)'
    WHEN estimated_cost_opportunity >= 20000 THEN 'Medium Opportunity ($20K-$50K)'
    ELSE 'Low Opportunity (<$20K)'
  END as opportunity_category,
  COUNT(*) as drg_count,
  SUM(total_encounters) as total_encounters,
  ROUND(SUM(estimated_cost_opportunity), 2) as total_cost_opportunity,
  ROUND(AVG(avg_los - gmlos_benchmark), 2) as avg_los_variance
FROM hls_amer_catalog.r_health_gold.capacity_management
GROUP BY
  CASE
    WHEN total_encounters >= 100 THEN 'High Volume (100+)'
    WHEN total_encounters >= 50 THEN 'Medium Volume (50-99)'
    ELSE 'Low Volume (<50)'
  END,
  CASE
    WHEN estimated_cost_opportunity >= 50000 THEN 'High Opportunity ($50K+)'
    WHEN estimated_cost_opportunity >= 20000 THEN 'Medium Opportunity ($20K-$50K)'
    ELSE 'Low Opportunity (<$20K)'
  END
ORDER BY total_cost_opportunity DESC;

-- ----------------------------------------------------------------------------
-- Query 6: Bed Days Utilization Analysis
-- Business Value: Understand bed day consumption and potential savings
-- ----------------------------------------------------------------------------
-- Query Name: bed_days_utilization

SELECT
  drg_code,
  primary_diagnosis_code,
  total_encounters,
  total_bed_days,
  ROUND(total_bed_days / total_encounters, 1) as bed_days_per_encounter,
  ROUND(gmlos_benchmark, 2) as benchmark_gmlos,
  ROUND(total_bed_days - (total_encounters * gmlos_benchmark), 0) as excess_bed_days,
  ROUND(((total_bed_days - (total_encounters * gmlos_benchmark)) / total_bed_days) * 100, 1) as excess_bed_days_pct,
  ROUND(estimated_cost_opportunity, 2) as cost_opportunity,
  optimization_priority
FROM hls_amer_catalog.r_health_gold.capacity_management
WHERE total_bed_days > (total_encounters * gmlos_benchmark)
ORDER BY excess_bed_days DESC
LIMIT 15;

-- ----------------------------------------------------------------------------
-- Query 7: Detailed Capacity Management Table
-- Business Value: Comprehensive view for drill-down analysis
-- ----------------------------------------------------------------------------
-- Query Name: detailed_capacity_data

SELECT
  drg_code,
  primary_diagnosis_code,
  total_encounters,
  ROUND(avg_los, 2) as avg_los,
  ROUND(gmlos_benchmark, 2) as gmlos_benchmark,
  ROUND(avg_los - gmlos_benchmark, 2) as los_variance,
  total_bed_days,
  ROUND(estimated_cost_opportunity, 2) as cost_opportunity,
  optimization_priority,
  CASE
    WHEN avg_los > gmlos_benchmark * 1.2 THEN 'Needs Immediate Attention'
    WHEN avg_los > gmlos_benchmark * 1.1 THEN 'Needs Improvement'
    WHEN avg_los > gmlos_benchmark THEN 'Minor Variance'
    ELSE 'Meeting Benchmark'
  END as performance_status
FROM hls_amer_catalog.r_health_gold.capacity_management
ORDER BY estimated_cost_opportunity DESC;

-- ----------------------------------------------------------------------------
-- Query 8: Cost Opportunity by DRG Category
-- Business Value: Aggregate opportunities by DRG groupings for strategic planning
-- ----------------------------------------------------------------------------
-- Query Name: drg_category_summary

SELECT
  SUBSTRING(drg_code, 1, 3) as drg_category,
  COUNT(DISTINCT drg_code) as unique_drgs,
  SUM(total_encounters) as total_encounters,
  ROUND(AVG(avg_los), 2) as avg_los,
  ROUND(AVG(gmlos_benchmark), 2) as avg_benchmark,
  SUM(total_bed_days) as total_bed_days,
  ROUND(SUM(estimated_cost_opportunity), 2) as total_cost_opportunity,
  COUNT(CASE WHEN optimization_priority = 'High' THEN 1 END) as high_priority_count
FROM hls_amer_catalog.r_health_gold.capacity_management
GROUP BY SUBSTRING(drg_code, 1, 3)
HAVING SUM(estimated_cost_opportunity) > 0
ORDER BY total_cost_opportunity DESC
LIMIT 15;
